import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

interface ChatMessageInput {
  role: "user" | "assistant";
  content: string;
}

interface ClientContext {
  now?: string; // device-local datetime, ISO 8601 with offset
  timezone?: string; // IANA name, e.g. "Asia/Riyadh"
  tasks?: {
    id: string;
    title: string;
    dueDate?: string | null;
    dueTime?: string | null;
    priority?: string;
    status?: string;
    isDone?: boolean;
  }[];
}

interface AnthropicContentBlock {
  type: string;
  text?: string;
  name?: string;
  input?: Record<string, unknown>;
}

interface AnthropicResponse {
  content: AnthropicContentBlock[];
  stop_reason?: string;
}

// Task actions the model can take. The function does NOT execute them —
// task state lives on the device (Hive + Firestore), so the app applies
// them and shows the reply text as confirmation.
const TASK_SCHEMA = {
  type: "object",
  properties: {
    title: {type: "string", description: "Short imperative title, e.g. 'Call mom'"},
    due_date: {
      type: "string",
      description: "Due date as YYYY-MM-DD, resolved from the user's " +
        "current local datetime. Omit if the user gave no date.",
    },
    due_time: {
      type: "string",
      description: "Due time as 24h HH:MM. Omit if the user gave no time.",
    },
    priority: {type: "string", enum: ["none", "low", "medium", "high"]},
    category: {type: "string", description: "e.g. Work, Personal. Omit unless clear."},
  },
  required: ["title"],
};

const TOOLS = [
  {
    name: "create_tasks",
    description:
      "Create one or more tasks/reminders the user asked for. Use one call " +
      "even when the user names several tasks in one sentence.",
    input_schema: {
      type: "object",
      properties: {tasks: {type: "array", items: TASK_SCHEMA}},
      required: ["tasks"],
    },
  },
  {
    name: "update_task",
    description:
      "Change an existing task (reschedule, rename, change priority). " +
      "Use the task id from the CURRENT TASKS list.",
    input_schema: {
      type: "object",
      properties: {
        id: {type: "string"},
        title: {type: "string"},
        due_date: {type: "string", description: "YYYY-MM-DD"},
        due_time: {type: "string", description: "24h HH:MM"},
        priority: {type: "string", enum: ["none", "low", "medium", "high"]},
      },
      required: ["id"],
    },
  },
  {
    name: "complete_task",
    description: "Mark an existing task as done.",
    input_schema: {
      type: "object",
      properties: {id: {type: "string"}},
      required: ["id"],
    },
  },
  {
    name: "delete_task",
    description: "Delete/cancel an existing task the user no longer wants.",
    input_schema: {
      type: "object",
      properties: {id: {type: "string"}},
      required: ["id"],
    },
  },
];

function buildSystemPrompt(ctx: ClientContext | undefined): string {
  const lines = [
    "You are Tell Me, a voice-first task assistant inside a tasks/projects/" +
      "calendar app. Users speak naturally; your job is to turn what they say " +
      "into task actions using the provided tools, plus a short spoken-style " +
      "confirmation.",
    "",
    "Rules:",
    "- When the user asks to be reminded of / to do something, call " +
      "create_tasks. Resolve relative dates ('tomorrow', 'in 3 days', " +
      "'next Monday', 'end of the month') against the CURRENT DATETIME below.",
    "- Vague timing: 'later today' → today, no time; 'sometime next week' → " +
      "the Monday of next week, no time; 'before the weekend' → this Friday.",
    "- Infer priority from language: 'urgent'/'asap'/'important' → high; " +
      "'whenever I get time'/'no rush' → low; otherwise omit it.",
    "- When the user changes their mind ('actually make that 6 pm', 'cancel " +
      "the milk one'), find the matching task in CURRENT TASKS and call " +
      "update_task / delete_task / complete_task.",
    "- If a requested date is in the past or impossible ('remind me " +
      "yesterday'), don't create anything — point it out and ask for a valid " +
      "time.",
    "- If the request is ambiguous (no clue what day, or two tasks could " +
      "match), ask ONE short clarifying question instead of guessing.",
    "- ALWAYS include a short text reply (max 2 sentences) confirming what " +
      "you did, e.g. \"Got it — 'Call mom', tomorrow 5 PM.\" Keep it warm " +
      "and conversational; it may be read aloud.",
    "- For general planning chat with no task action, just reply normally.",
  ];

  if (ctx?.now) {
    lines.push("", `CURRENT DATETIME: ${ctx.now}` +
      (ctx.timezone ? ` (${ctx.timezone})` : ""));
  }
  if (ctx?.tasks && ctx.tasks.length > 0) {
    lines.push("", "CURRENT TASKS:", JSON.stringify(ctx.tasks));
  } else {
    lines.push("", "CURRENT TASKS: (none)");
  }
  return lines.join("\n");
}

/**
 * Callable HTTPS function that proxies chat messages to the Anthropic
 * Messages API with task tools. The API key stays server-side (as a
 * Firebase secret) so it never ships inside the compiled app.
 *
 * Returns {reply: string, actions: [{name, input}]} — the app executes
 * the actions locally against its task store.
 */
export const chatWithAI = onCall(
  {secrets: [anthropicApiKey], region: "us-central1"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const messages = request.data?.messages as ChatMessageInput[] | undefined;
    if (!Array.isArray(messages) || messages.length === 0) {
      throw new HttpsError("invalid-argument", "\"messages\" is required.");
    }
    // The Anthropic API requires the first message to be a user turn.
    // Drop any leading assistant messages (e.g. the app's greeting).
    const trimmed = messages.slice(
      messages.findIndex((m) => m.role === "user"),
    );
    if (trimmed.length === 0 || trimmed[0].role !== "user") {
      throw new HttpsError("invalid-argument", "No user message provided.");
    }

    const context = request.data?.context as ClientContext | undefined;

    let response: Response;
    try {
      response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-api-key": anthropicApiKey.value(),
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: "claude-sonnet-5",
          max_tokens: 1024,
          system: buildSystemPrompt(context),
          tools: TOOLS,
          messages: trimmed.map((m) => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });
    } catch (error) {
      console.error("Anthropic request failed to send", error);
      throw new HttpsError("unavailable", "Couldn't reach the AI service.");
    }

    if (!response.ok) {
      const body = await response.text();
      console.error("Anthropic API error", response.status, body);
      throw new HttpsError("internal", "The AI service returned an error.");
    }

    const data = (await response.json()) as AnthropicResponse;
    const reply = data.content
      .filter((c) => c.type === "text" && c.text)
      .map((c) => c.text)
      .join("\n")
      .trim();
    const actions = data.content
      .filter((c) => c.type === "tool_use" && c.name)
      .map((c) => ({name: c.name, input: c.input ?? {}}));

    return {reply, actions};
  }
);

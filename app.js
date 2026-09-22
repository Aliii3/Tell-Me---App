const screens = document.querySelectorAll('.screen');
const modeLabel = document.getElementById('mode-lbl');
const chatInput = document.getElementById('chatIn');
const voiceButton = document.getElementById('voiceBtn');
const voiceButtonLabel = document.getElementById('voiceBtnLabel');
const voiceStatus = document.getElementById('voiceStatus');
let isDark = document.body.classList.contains('dark');
let isListening = false;
let recognition = null;

function getRecognition() {
  if (recognition) return recognition;

  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SpeechRecognition) return null;

  recognition = new SpeechRecognition();
  recognition.lang = 'en-US';
  recognition.interimResults = true;
  recognition.continuous = false;

  recognition.onstart = () => {
    isListening = true;
    syncVoiceUi('Listening... speak now.');
  };

  recognition.onresult = event => {
    const transcript = Array.from(event.results)
      .map(result => result[0]?.transcript || '')
      .join(' ')
      .trim();

    if (chatInput) {
      chatInput.value = transcript;
    }

    const latestResult = event.results[event.results.length - 1];
    if (latestResult?.isFinal) {
      syncVoiceUi('Voice captured. You can send it or keep editing.');
    } else {
      syncVoiceUi('Listening... capturing your words.');
    }
  };

  recognition.onerror = event => {
    isListening = false;
    syncVoiceUi(`Voice input unavailable: ${event.error}.`);
  };

  recognition.onend = () => {
    isListening = false;
    if (voiceStatus?.textContent === 'Listening... speak now.' || voiceStatus?.textContent === 'Listening... capturing your words.') {
      syncVoiceUi('Voice input stopped. Tap Talk to try again.');
      return;
    }
    syncVoiceUi(voiceStatus?.textContent || 'Tap Talk to speak with Tell Me.');
  };

  return recognition;
}

function syncModeLabel() {
  if (!modeLabel) return;
  modeLabel.textContent = isDark ? 'Dark Mode' : 'Light Mode';
}

function syncVoiceUi(message) {
  if (voiceButton) {
    voiceButton.classList.toggle('is-listening', isListening);
    voiceButton.setAttribute('aria-pressed', String(isListening));
  }

  if (voiceButtonLabel) {
    voiceButtonLabel.textContent = isListening ? 'Listening' : 'Talk';
  }

  if (voiceStatus && message) {
    voiceStatus.textContent = message;
  }
}

function goTo(id) {
  const target = document.getElementById(`s-${id}`);
  if (!target) return;

  screens.forEach(screen => screen.classList.remove('active'));
  target.classList.add('active');
  window.location.hash = id;
}

function toggleMode() {
  isDark = !isDark;
  document.body.classList.toggle('dark', isDark);
  document.body.classList.toggle('light', !isDark);
  syncModeLabel();
}

function toggleTask(row) {
  const checkbox = row.querySelector('.task-cb');
  const taskName = row.querySelector('.task-nm');
  if (!checkbox || !taskName) return;

  checkbox.classList.toggle('done');
  taskName.classList.toggle('done');
}

function toggleFolder(hdr) {
  hdr.closest('.lm-folder').classList.toggle('collapsed');
}

function sendMsg() {
  const value = chatInput?.value.trim();
  if (!value) return;

  const scrollArea = document.getElementById('chat-scroll');
  if (!scrollArea) return;

  const userLabel = document.createElement('div');
  userLabel.className = 'msg-label ml-user';
  userLabel.textContent = 'You';

  const userBubble = document.createElement('div');
  userBubble.className = 'bubble-user';
  userBubble.textContent = value;

  scrollArea.appendChild(userLabel);
  scrollArea.appendChild(userBubble);
  chatInput.value = '';
  scrollArea.scrollTop = scrollArea.scrollHeight;

  setTimeout(() => {
    const assistantLabel = document.createElement('div');
    assistantLabel.className = 'msg-label ml-ai';
    assistantLabel.textContent = 'Assistant';

    const assistantBubble = document.createElement('div');
    assistantBubble.className = 'bubble-ai';
    assistantBubble.innerHTML = 'Got it! I\'ve added that to your plan and updated your schedule. <span style="color:var(--cyan);font-weight:600;">Anything else?</span> ✦';

    scrollArea.appendChild(assistantLabel);
    scrollArea.appendChild(assistantBubble);
    scrollArea.scrollTop = scrollArea.scrollHeight;
  }, 700);
}

function toggleVoiceInput() {
  const speechRecognition = getRecognition();
  if (!speechRecognition) {
    syncVoiceUi('Voice input is not supported in this browser.');
    return;
  }

  if (isListening) {
    speechRecognition.stop();
    return;
  }

  speechRecognition.start();
}

function bootFromHash() {
  const screenId = window.location.hash.replace('#', '') || 'splash';
  goTo(screenId);
}

if (chatInput) {
  chatInput.addEventListener('keydown', event => {
    if (event.key === 'Enter') sendMsg();
  });
}

syncModeLabel();
syncVoiceUi('Tap Talk to speak with Tell Me.');
bootFromHash();

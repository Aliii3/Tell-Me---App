class AppStrings {
  AppStrings._();

  // App
  static const appName = 'Tell Me';
  static const tagline = 'AI Powered Smart Assistant!';

  // Splash
  static const splashManage = 'Manage';
  static const splashYour = 'your';
  static const splashTasks = 'tasks';
  static const splashGetStarted = 'Get started';

  // Onboarding
  static const getStarted = 'Get Started';
  static const signIn = 'I already have an account';
  static const smartLearning = '✦ Voice-first planning';
  static const onboardingTitle1 = 'Tell Me —';
  static const onboardingSubtitle = 'AI Powered Smart Assistant!';

  // Features
  static const featureVoice = 'Voice';
  static const featureReminders = 'Reminders';
  static const featureChat = 'AI Chat';
  static const featureTasks = 'Tasks';
  static const featurePlanning = 'Planning';
  static const featureCalendar = 'Calendar';

  // Auth
  static const emailHint = 'Email address';
  static const passwordHint = 'Password';
  static const loginTitle = 'Welcome back';
  static const loginSubtitle = 'Sign in to continue';

  // Home / Dashboard
  static const helloUser = 'Hello,';
  static const dashboardSubtitle = 'Look at your projects.';
  static const todayProgress = 'Today\'s Progress';
  static const tasksCount = '10/12 tasks';
  static const newProject = 'New project';
  static const ongoing = 'Ongoing';
  static const future = 'Future';
  static const highPriority = 'High priority ↑';

  // Tasks
  static const goodMorning = 'Good';
  static const morning = 'Morning';
  static const ongoingFolder = 'Ongoing';
  static const upcomingFolder = 'Upcoming';
  static const completedFolder = 'Completed';
  static const today = 'Today';
  static const tomorrow = 'Tomorrow';
  static const addTask = 'Add task';
  static const taskTitle = 'Task title';
  static const cancel = 'Cancel';
  static const add = 'Add';

  // Chat
  static const tellMe = 'Tell Me';
  static const tapToSpeak = 'Tap to speak with Tell Me.';
  static const listening = 'Listening';
  static const talk = 'Talk';
  static const chatHint = 'Ask Tell Me anything…';
  static const send = 'Send';
  static const assistant = 'Assistant';
  static const you = 'You';
  static const generateMoodboard = 'Generate moodboard';
  static const outlineTechSpecs = 'Outline tech specs';
  static const addToCalendar = 'Add to Calendar';
  static const voiceStopped = 'Voice input stopped. Tap Talk to try again.';
  static const voiceCaptured = 'Voice captured. You can send it or keep editing.';
  static const voiceCapturing = 'Listening... capturing your words.';
  static const voiceStart = 'Tap Talk to speak with Tell Me.';

  // Calendar
  static const meetings = 'Meeting';
  static const monday = 'Monday';

  // Settings
  static const settings = 'Settings';
  static const intelligence = 'Intelligence';
  static const experience = 'Experience';
  static const cognitiveMemory = 'Cognitive Memory';
  static const cognitiveMemoryDesc = 'Remembers context across sessions';
  static const appearance = 'Appearance';
  static const lightMode = 'Light Mode';
  static const darkMode = 'Dark Mode';
  static const voiceFeedback = 'Voice Feedback';
  static const voiceFeedbackDesc = 'Hands-free responses';
  static const language = 'Language';
  static const languageValue = 'English (US)';
  static const privacyData = 'Privacy & Data';
  static const privacyDataDesc = 'Conversations are stored to improve responses';
  static const signOut = 'Sign Out';
  static const deleteAccount = 'Delete Account';
}

class AppKeys {
  AppKeys._();

  static const themeMode = 'theme_mode';
  static const cognitiveMemory = 'cognitive_memory';
  static const voiceFeedback = 'voice_feedback';
  static const language = 'language';
  static const tasksBox = 'tasks_box';
  static const projectsBox = 'projects_box';
  static const eventsBox = 'events_box';
  static const firstLaunch = 'first_launch';
}

class AppDurations {
  AppDurations._();

  static const splashAdvance = Duration(milliseconds: 2500);
  static const aiResponseDelay = Duration(milliseconds: 700);
  static const folderToggle = Duration(milliseconds: 300);
  static const screenTransition = Duration(milliseconds: 350);
  static const voicePulse = Duration(milliseconds: 1200);
  static const progressBarDelay = Duration(milliseconds: 400);
}

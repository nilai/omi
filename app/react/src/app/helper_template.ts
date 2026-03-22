// Helper function to get template display name from styleId
export const getTemplateDisplayName = (styleId: string): string => {
  switch (styleId) {
    case 'autopilot':
      return 'Autopilot mode';
    case 'meeting-secretary':
    case 'meeting':
      return 'Meeting secretary';
    case 'sales-followup':
    case 'sales':
      return 'Sales follow-up';
    case 'project-sync':
      return 'Project sync';
    case 'learning-notes':
    case 'learning':
      return 'Learning notes';
    case 'adhd-friendly':
    case 'adhd':
      return 'ADHD-friendly';
    case 'reflection-insights':
      return 'Reflection';
    case 'interview-research':
      return 'Interview';
    case 'investor-review':
      return 'Decision review';
    default:
      return 'Autopilot mode';
  }
};

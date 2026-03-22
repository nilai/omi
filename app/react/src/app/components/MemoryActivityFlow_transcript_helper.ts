// Helper function to get transcript data based on memory ID
export const getInitialTranscript = (memoryId: number) => {
  switch (memoryId) {
    case 1: // Team standup discussion on API migration
      return [
        { speaker: 'Team Lead', time: '00:00', text: 'Let\'s discuss the API migration timeline for this quarter.' },
        { speaker: 'Sarah', time: '00:15', text: 'I think we should start with the authentication service. It\'s the most critical path.' },
        { speaker: 'Alex', time: '00:32', text: 'Agreed. What about the database schema changes we need to make?' },
        { speaker: 'Unidentified', time: '00:42', text: 'We also need to consider backward compatibility for existing clients.' },
        { speaker: 'Team Lead', time: '00:48', text: 'Good point. We\'ll need a phased approach to minimize downtime.' },
        { speaker: 'Sarah', time: '01:05', text: 'The infrastructure team should be looped in early. They seem pretty overloaded already.' },
        { speaker: 'Unidentified', time: '01:18', text: 'I can reach out to them today. I worked with their team lead on a previous project.' },
        { speaker: 'Alex', time: '01:25', text: 'That would be great. We really need their buy-in early.' },
        { speaker: 'Team Lead', time: '01:35', text: 'Let\'s also think about the testing strategy. What\'s our plan there?' },
        { speaker: 'Sarah', time: '01:48', text: 'We should set up a staging environment that mirrors production as closely as possible.' },
        { speaker: 'Unidentified', time: '02:02', text: 'I can help configure the staging environment. We did something similar for the payment service migration.' },
        { speaker: 'Sarah', time: '02:14', text: 'Infra team seems overloaded. Maybe we should loop in Sarah from the platform team to help?', hasMarkedMemo: true },
        { speaker: 'Alex', time: '02:15', text: 'Perfect. How long do you think that will take?' },
        { speaker: 'Unidentified', time: '02:22', text: 'Probably about a week if we start this week. Two weeks if we wait.' },
        { speaker: 'Team Lead', time: '02:35', text: 'Let\'s aim to start this week then. Time is tight as it is.' },
        { speaker: 'Sarah', time: '02:48', text: 'Agreed. I\'ll start documenting the authentication flow requirements today.' },
      ];
    case 2: // Coffee chat with Alex about product strategy
      return [
        { speaker: 'You', time: '00:00', text: 'I\'ve been thinking about how we differentiate ourselves in this market.' },
        { speaker: 'Alex', time: '00:08', text: 'Yeah, it\'s getting pretty crowded. What are your thoughts?' },
        { speaker: 'You', time: '00:15', text: 'I think our strength is in understanding user behavior patterns, but I\'m not sure that\'s enough.' },
        { speaker: 'Alex', time: '00:28', text: 'Actually, I think there\'s something there. Have you considered focusing specifically on neurodivergent users?' },
        { speaker: 'You', time: '00:42', text: 'Neurodivergent users? That\'s interesting. How do you mean?' },
        { speaker: 'Alex', time: '00:50', text: 'Well, ADHD users, people on the autism spectrum... they have specific needs that most productivity apps completely ignore.' },
        { speaker: 'You', time: '01:05', text: 'That could be a real positioning opportunity. Nobody else is doing that.' },
        { speaker: 'Alex', time: '01:15', text: 'Exactly. And it\'s not just a niche market either. Conservative estimates put it at 15-20% of the population.' },
        { speaker: 'You', time: '01:30', text: 'The more I think about it, the more it makes sense. Our whole interface philosophy already aligns with that.' },
        { speaker: 'Alex', time: '01:45', text: 'Right! You\'re already doing it intuitively. Just need to make it explicit and go deeper.' },
        { speaker: 'You', time: '02:00', text: 'I\'m going to spend some time researching this. This could be our angle.' },
        { speaker: 'Alex', time: '02:10', text: 'I think you\'re onto something big here. Let me know if you want to brainstorm more.' },
      ];
    case 7: // Product launch planning with marketing team
      return [
        { speaker: 'Marketing Lead', time: '00:00', text: 'Let\'s finalize the go-to-market strategy for the Q2 launch.' },
        { speaker: 'You', time: '00:10', text: 'I\'m thinking we need a phased approach rather than a big bang launch.' },
        { speaker: 'Marketing Lead', time: '00:20', text: 'I agree. What phases are you thinking?' },
        { speaker: 'Designer', time: '00:28', text: 'We could start with our beta users. They\'ve been incredibly engaged.' },
        { speaker: 'You', time: '00:38', text: 'Phase one: beta users. They give us real-world feedback and testimonials.' },
        { speaker: 'Marketing Lead', time: '00:50', text: 'Perfect. Then phase two could be influencer partnerships to build awareness.' },
        { speaker: 'Designer', time: '01:05', text: 'We should target productivity and tech influencers specifically.' },
        { speaker: 'You', time: '01:18', text: 'And phase three is the public launch with all the social proof we\'ve built.' },
        { speaker: 'Marketing Lead', time: '01:32', text: 'This gives us time to refine messaging based on what resonates.' },
        { speaker: 'Designer', time: '01:48', text: 'I like it. Much lower risk than going wide immediately.' },
        { speaker: 'You', time: '02:00', text: 'Exactly. We build momentum gradually and learn as we go.' },
        { speaker: 'Marketing Lead', time: '02:15', text: 'Let\'s draft a detailed timeline for each phase.' },
      ];
    case 8: // Investor meeting - Series A funding
      return [
        { speaker: 'Investor', time: '00:00', text: 'Thanks for presenting today. Your growth numbers look impressive.' },
        { speaker: 'You', time: '00:08', text: 'Thank you. We\'ve been really focused on sustainable growth and user retention.' },
        { speaker: 'Investor', time: '00:18', text: 'I noticed your retention curve is quite strong. Can you walk me through that?' },
        { speaker: 'You', time: '00:30', text: 'We\'re seeing 65% Day 30 retention and 45% Day 90 retention, which is well above industry benchmarks.' },
        { speaker: 'Investor', time: '00:48', text: 'That\'s exceptional for this category. What\'s driving that?' },
        { speaker: 'You', time: '01:00', text: 'We\'ve built the product around daily habits rather than project management, so users keep coming back.' },
        { speaker: 'Investor', time: '01:18', text: 'Interesting. Now let\'s talk about unit economics. What\'s your CAC to LTV ratio?' },
        { speaker: 'You', time: '01:32', text: 'We\'re at 1:4 right now, with CAC around $35 and LTV projecting to $140 based on current cohorts.' },
        { speaker: 'Investor', time: '01:50', text: 'And how are you acquiring users currently?' },
        { speaker: 'You', time: '02:02', text: 'It\'s been primarily organic and content marketing. Paid acquisition is still under 20%.' },
        { speaker: 'Investor', time: '02:20', text: 'That\'s healthy. Gives you room to scale with paid when you\'re ready.' },
        { speaker: 'You', time: '02:35', text: 'Exactly our thinking. We want to nail product-market fit before scaling aggressively.' },
      ];
    case 4: // Client feedback call
      return [
        { speaker: 'Client', time: '00:00', text: 'We\'ve been using the new dashboard for about two weeks now.' },
        { speaker: 'You', time: '00:08', text: 'Great! How\'s it working for your team?' },
        { speaker: 'Client', time: '00:15', text: 'The data visualization features are fantastic. Really helps us see patterns we were missing.' },
        { speaker: 'You', time: '00:28', text: 'That\'s exactly what we were hoping for. Anything that could be better?' },
        { speaker: 'Client', time: '00:40', text: 'Yes, actually. We need more customization options for the reports.' },
        { speaker: 'You', time: '00:50', text: 'Can you give me an example of what you\'d like to customize?' },
        { speaker: 'Client', time: '01:02', text: 'Things like filtering by custom date ranges, choosing which metrics to include, that sort of thing.' },
        { speaker: 'You', time: '01:18', text: 'That makes sense. Anything else on the wishlist?' },
        { speaker: 'Client', time: '01:28', text: 'Export functionality is the big one. We need to get this data into our board presentations.' },
        { speaker: 'You', time: '01:42', text: 'PDF export? Or are you thinking Excel format?' },
        { speaker: 'Client', time: '01:52', text: 'Both would be ideal, but Excel is higher priority for us.' },
        { speaker: 'You', time: '02:05', text: 'Got it. I\'ll prioritize the export functionality for the next release.' },
      ];
    case 5: // Weekly review and planning
      return [
        { speaker: 'You', time: '00:00', text: 'Let\'s review our progress on Q1 goals.' },
        { speaker: 'Team Lead', time: '00:10', text: 'Backend infrastructure is on track. We hit all our milestones this week.' },
        { speaker: 'Designer', time: '00:22', text: 'Design system is also looking good. Just need final review on the component library.' },
        { speaker: 'You', time: '00:35', text: 'Great work. What about mobile app development?' },
        { speaker: 'Mobile Lead', time: '00:45', text: 'We\'re behind schedule, to be honest. Maybe two weeks behind our original timeline.' },
        { speaker: 'You', time: '00:58', text: 'What\'s the blocker?' },
        { speaker: 'Mobile Lead', time: '01:08', text: 'Mainly bandwidth. The team is stretched thin with both iOS and Android builds.' },
        { speaker: 'Designer', time: '01:22', text: 'Could we bring in contractor help for the Android side?' },
        { speaker: 'You', time: '01:35', text: 'That\'s worth exploring. We need to get back on track.' },
        { speaker: 'Team Lead', time: '01:48', text: 'I might be able to shift one frontend developer to help with mobile.' },
        { speaker: 'You', time: '02:02', text: 'Let\'s do that. Mobile is critical for Q1.' },
        { speaker: 'Mobile Lead', time: '02:15', text: 'That would help a lot. With extra resources, we can catch up.' },
      ];
    default:
      return [
        { speaker: 'Speaker 1', time: '00:00', text: 'This is the beginning of the conversation.' },
        { speaker: 'Speaker 2', time: '00:10', text: 'Thanks for taking the time to discuss this.' },
        { speaker: 'Speaker 1', time: '00:20', text: 'Of course. Let\'s dive into the details.' },
      ];
  }
};
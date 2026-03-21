import { Users, Brain, AlertCircle, Target, List } from 'lucide-react';
import { useState, useEffect } from 'react';

interface MemoryGraphSummaryProps {
  timeRange: '7days' | '30days' | '90days';
  setTimeRange: (range: '7days' | '30days' | '90days') => void;
}

export function MemoryGraphSummary({ timeRange, setTimeRange }: MemoryGraphSummaryProps) {
  const [isAnalyzing, setIsAnalyzing] = useState(true);
  const [visibleSections, setVisibleSections] = useState<number>(0);

  // Mock data based on time range
  const getData = () => {
    if (timeRange === '7days') {
      return {
        people: [
          { name: 'Alex', count: 6 },
          { name: 'Sarah', count: 4 },
          { name: 'John', count: 2 },
        ],
        topics: [
          { name: 'API migration', intensity: 100 },
          { name: 'Hiring bandwidth', intensity: 67 },
          { name: 'Pricing uncertainty', intensity: 50 },
        ],
        threads: [
          { text: 'API migration decision pending' },
          { text: 'Team hiring unresolved' },
          { text: 'Launch timeline slipping' },
        ],
        attention: [
          { category: 'Product', percentage: 70 },
          { category: 'Engineering', percentage: 50 },
          { category: 'Hiring', percentage: 20 },
        ],
        recentMemories: [
          { text: 'API sync meeting' },
          { text: 'Hiring planning' },
          { text: 'Infrastructure discussion' },
        ],
      };
    } else if (timeRange === '30days') {
      return {
        people: [
          { name: 'Jordan', count: 12 },
          { name: 'Alex', count: 10 },
          { name: 'Sarah', count: 8 },
          { name: 'Chris', count: 5 },
        ],
        topics: [
          { name: 'Product roadmap', intensity: 100 },
          { name: 'User research', intensity: 85 },
          { name: 'Team dynamics', intensity: 60 },
          { name: 'Marketing strategy', intensity: 45 },
        ],
        threads: [
          { text: 'Q2 roadmap needs finalization' },
          { text: 'User feedback integration pending' },
          { text: 'Team structure discussion ongoing' },
          { text: 'Budget allocation unresolved' },
        ],
        attention: [
          { category: 'Product', percentage: 65 },
          { category: 'People', percentage: 55 },
          { category: 'Engineering', percentage: 40 },
          { category: 'Marketing', percentage: 30 },
        ],
        recentMemories: [
          { text: 'Quarterly planning session' },
          { text: 'User interview synthesis' },
          { text: 'Team retrospective' },
          { text: 'Marketing campaign review' },
        ],
      };
    } else {
      return {
        people: [
          { name: 'Jordan', count: 24 },
          { name: 'Alex', count: 18 },
          { name: 'Sarah', count: 15 },
          { name: 'Chris', count: 12 },
          { name: 'Taylor', count: 8 },
        ],
        topics: [
          { name: 'Strategic planning', intensity: 100 },
          { name: 'Product development', intensity: 90 },
          { name: 'Customer feedback', intensity: 75 },
          { name: 'Team growth', intensity: 65 },
          { name: 'Technology stack', intensity: 50 },
        ],
        threads: [
          { text: 'Annual strategy review incomplete' },
          { text: 'Product-market fit validation needed' },
          { text: 'Customer retention strategy pending' },
          { text: 'Scaling infrastructure unresolved' },
          { text: 'Leadership hiring in progress' },
        ],
        attention: [
          { category: 'Strategy', percentage: 75 },
          { category: 'Product', percentage: 70 },
          { category: 'Customers', percentage: 60 },
          { category: 'People', percentage: 50 },
          { category: 'Engineering', percentage: 45 },
        ],
        recentMemories: [
          { text: 'Strategic planning offsite' },
          { text: 'Customer advisory board' },
          { text: 'Product vision workshop' },
          { text: 'Engineering all-hands' },
          { text: 'Leadership sync' },
        ],
      };
    }
  };

  const data = getData();

  useEffect(() => {
    setIsAnalyzing(true);
    setVisibleSections(0);

    const analyzingTimer = setTimeout(() => {
      setIsAnalyzing(false);
      
      const sectionTimers: NodeJS.Timeout[] = [];
      for (let i = 1; i <= 5; i++) {
        const timer = setTimeout(() => {
          setVisibleSections(i);
        }, i * 400);
        sectionTimers.push(timer);
      }

      return () => {
        sectionTimers.forEach(timer => clearTimeout(timer));
      };
    }, 3500);

    return () => {
      clearTimeout(analyzingTimer);
    };
  }, [timeRange]);

  const maxPeopleCount = Math.max(...data.people.map(p => p.count));
  const maxTopicIntensity = Math.max(...data.topics.map(t => t.intensity));
  const maxAttention = Math.max(...data.attention.map(a => a.percentage));

  return (
    <div className="mb-6">
      {/* Memory Graph Summary content removed */}
    </div>
  );
}
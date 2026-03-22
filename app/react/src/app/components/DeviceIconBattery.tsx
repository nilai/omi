interface DeviceIconBatteryProps {
  className?: string;
  batteryLevel?: 'full' | 'medium' | 'low' | 'disconnected';
  batteryPercentage?: number; // Add percentage prop
}

// Helper function to determine battery level from percentage
function getBatteryLevelFromPercentage(percentage: number): 'full' | 'medium' | 'low' {
  if (percentage >= 50) return 'full';      // Green: 50-100%
  if (percentage >= 20) return 'medium';    // Yellow: 20-49%
  return 'low';                              // Red: 0-19%
}

export function DeviceIconBattery({ 
  className = "w-[18px] h-[18px]",
  batteryLevel,
  batteryPercentage
}: DeviceIconBatteryProps) {
  
  // Determine battery level from percentage if provided, otherwise use batteryLevel
  const level = batteryPercentage !== undefined 
    ? getBatteryLevelFromPercentage(batteryPercentage)
    : (batteryLevel || 'disconnected');

  // Color schemes for different battery levels
  const colorSchemes = {
    full: {
      outerGradientStart: '#d4f4dd',
      outerGradientEnd: '#a8e6bc',
      outerStroke: '#34c759',
      ringGradientStart: '#34c759',
      ringGradientMid: '#66d97f',
      ringGradientEnd: '#28a745',
      innerFill: '#c8f5d6',
      accentFill: '#34c759'
    },
    medium: {
      outerGradientStart: '#fff9e6',
      outerGradientEnd: '#ffe9a8',
      outerStroke: '#ffb340',
      ringGradientStart: '#ffb340',
      ringGradientMid: '#ffc866',
      ringGradientEnd: '#ff9f00',
      innerFill: '#fff4d4',
      accentFill: '#ffb340'
    },
    low: {
      outerGradientStart: '#ffe8e6',
      outerGradientEnd: '#ffbfb8',
      outerStroke: '#ff3b30',
      ringGradientStart: '#ff3b30',
      ringGradientMid: '#ff6259',
      ringGradientEnd: '#e62e24',
      innerFill: '#ffd6d3',
      accentFill: '#ff3b30'
    },
    disconnected: {
      outerGradientStart: '#f3f4f6',
      outerGradientEnd: '#d1d5db',
      outerStroke: '#6b7280',
      ringGradientStart: '#9ca3af',
      ringGradientMid: '#d1d5db',
      ringGradientEnd: '#6b7280',
      innerFill: '#e5e7eb',
      accentFill: '#9ca3af'
    }
  };

  const colors = colorSchemes[level];

  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      {/* Outer circle - device body */}
      <circle
        cx="12"
        cy="12"
        r="10"
        fill={`url(#deviceGradient-${level})`}
        stroke={colors.outerStroke}
        strokeWidth="0.5"
      />
      
      {/* Inner ring - center button */}
      <circle
        cx="12"
        cy="12"
        r="5"
        fill="none"
        stroke={`url(#ringGradient-${level})`}
        strokeWidth="1.5"
      />
      
      {/* Inner circle - button center */}
      <circle
        cx="12"
        cy="12"
        r="3"
        fill={colors.innerFill}
        opacity="0.8"
      />
      
      {/* Small accent dot */}
      <circle
        cx="12"
        cy="8"
        r="1"
        fill={colors.accentFill}
        opacity="0.6"
      />
      
      {/* Gradients */}
      <defs>
        <linearGradient id={`deviceGradient-${level}`} x1="12" y1="2" x2="12" y2="22">
          <stop offset="0%" stopColor={colors.outerGradientStart} />
          <stop offset="100%" stopColor={colors.outerGradientEnd} />
        </linearGradient>
        <linearGradient id={`ringGradient-${level}`} x1="12" y1="7" x2="12" y2="17">
          <stop offset="0%" stopColor={colors.ringGradientStart} />
          <stop offset="50%" stopColor={colors.ringGradientMid} />
          <stop offset="100%" stopColor={colors.ringGradientEnd} />
        </linearGradient>
      </defs>
    </svg>
  );
}
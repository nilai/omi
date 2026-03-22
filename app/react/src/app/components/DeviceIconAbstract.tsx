interface DeviceIconAbstractProps {
  className?: string;
}

export function DeviceIconAbstract({ className = "w-[18px] h-[18px]" }: DeviceIconAbstractProps) {
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
        fill="url(#deviceGradient)"
        stroke="#6b7280"
        strokeWidth="0.5"
      />
      
      {/* Inner ring - center button */}
      <circle
        cx="12"
        cy="12"
        r="5"
        fill="none"
        stroke="url(#ringGradient)"
        strokeWidth="1.5"
      />
      
      {/* Inner circle - button center */}
      <circle
        cx="12"
        cy="12"
        r="3"
        fill="#e5e7eb"
        opacity="0.8"
      />
      
      {/* Small accent dot */}
      <circle
        cx="12"
        cy="8"
        r="1"
        fill="#9ca3af"
        opacity="0.6"
      />
      
      {/* Gradients */}
      <defs>
        <linearGradient id="deviceGradient" x1="12" y1="2" x2="12" y2="22">
          <stop offset="0%" stopColor="#f3f4f6" />
          <stop offset="100%" stopColor="#d1d5db" />
        </linearGradient>
        <linearGradient id="ringGradient" x1="12" y1="7" x2="12" y2="17">
          <stop offset="0%" stopColor="#9ca3af" />
          <stop offset="50%" stopColor="#d1d5db" />
          <stop offset="100%" stopColor="#6b7280" />
        </linearGradient>
      </defs>
    </svg>
  );
}

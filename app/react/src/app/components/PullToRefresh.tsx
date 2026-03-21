import { useState, useRef, useEffect, ReactNode } from 'react';
import { RotateCw } from 'lucide-react';

interface PullToRefreshProps {
  onRefresh: () => Promise<void>;
  children: ReactNode;
  disabled?: boolean;
}

export function PullToRefresh({ onRefresh, children, disabled = false }: PullToRefreshProps) {
  const [pullDistance, setPullDistance] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [isDragging, setIsDragging] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const startY = useRef(0);
  const currentY = useRef(0);
  const scrollTop = useRef(0);
  
  const PULL_THRESHOLD = 80; // Minimum pull distance to trigger refresh
  const MAX_PULL = 120; // Maximum pull distance for visual effect

  const handleMouseDown = (e: React.MouseEvent) => {
    if (disabled || isRefreshing) return;
    
    const container = containerRef.current;
    if (!container) return;
    
    // Only trigger if we're at the top of the scroll
    if (container.scrollTop === 0) {
      setIsDragging(true);
      startY.current = e.clientY;
      scrollTop.current = container.scrollTop;
    }
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging || disabled || isRefreshing) return;
    
    currentY.current = e.clientY;
    const delta = currentY.current - startY.current;
    
    // Only allow pulling down when at top
    if (delta > 0 && scrollTop.current === 0) {
      // Apply resistance to make it feel more natural
      const resistance = 0.5;
      const distance = Math.min(delta * resistance, MAX_PULL);
      setPullDistance(distance);
    }
  };

  const handleMouseUp = async () => {
    if (!isDragging) return;
    
    setIsDragging(false);
    
    // If pulled far enough, trigger refresh
    if (pullDistance >= PULL_THRESHOLD && !isRefreshing) {
      setIsRefreshing(true);
      setPullDistance(PULL_THRESHOLD); // Lock at threshold during refresh
      
      try {
        await onRefresh();
      } catch (error) {
        console.error('Refresh failed:', error);
      } finally {
        // Smooth reset animation
        setTimeout(() => {
          setIsRefreshing(false);
          setPullDistance(0);
        }, 500);
      }
    } else {
      // Snap back if not pulled far enough
      setPullDistance(0);
    }
  };

  // Mouse leave handler
  const handleMouseLeave = () => {
    if (isDragging) {
      handleMouseUp();
    }
  };

  // Calculate rotation for spinner
  const getRotation = () => {
    if (isRefreshing) return 360;
    return (pullDistance / PULL_THRESHOLD) * 180;
  };

  // Calculate opacity
  const getOpacity = () => {
    if (isRefreshing) return 1;
    return Math.min(pullDistance / PULL_THRESHOLD, 1);
  };

  return (
    <div
      ref={containerRef}
      className="h-full overflow-y-auto relative"
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseLeave}
      style={{
        cursor: isDragging ? 'grabbing' : 'default',
        userSelect: isDragging ? 'none' : 'auto',
      }}
    >
      {/* Pull to refresh indicator */}
      <div
        className="absolute top-0 left-0 right-0 flex items-center justify-center pointer-events-none z-10"
        style={{
          transform: `translateY(${pullDistance - 50}px)`,
          transition: isDragging ? 'none' : 'transform 0.3s ease-out',
          opacity: getOpacity(),
        }}
      >
        <div className="bg-white rounded-full p-2.5 shadow-lg border border-black/[0.08]">
          <RotateCw 
            className="w-5 h-5 text-[#007aff]" 
            style={{
              transform: `rotate(${getRotation()}deg)`,
              transition: isRefreshing ? 'transform 0.6s linear' : 'transform 0.2s ease-out',
              animation: isRefreshing ? 'spin 1s linear infinite' : 'none',
            }}
          />
        </div>
      </div>

      {/* Status text */}
      {(pullDistance > 0 || isRefreshing) && (
        <div
          className="absolute top-0 left-0 right-0 flex items-center justify-center pointer-events-none z-10"
          style={{
            transform: `translateY(${pullDistance + 10}px)`,
            transition: isDragging ? 'none' : 'transform 0.3s ease-out',
            opacity: getOpacity(),
          }}
        >
          <p className="text-[13px] font-medium text-[#8e8e93]">
            {isRefreshing 
              ? 'Refreshing...' 
              : pullDistance >= PULL_THRESHOLD 
                ? 'Release to refresh' 
                : 'Pull to refresh'
            }
          </p>
        </div>
      )}

      {/* Content with offset when pulling */}
      <div
        style={{
          transform: `translateY(${pullDistance}px)`,
          transition: isDragging ? 'none' : 'transform 0.3s ease-out',
        }}
      >
        {children}
      </div>

      <style>{`
        @keyframes spin {
          from {
            transform: rotate(0deg);
          }
          to {
            transform: rotate(360deg);
          }
        }
      `}</style>
    </div>
  );
}

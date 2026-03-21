import { ChevronLeft } from 'lucide-react';
import deviceIcon from 'figma:asset/4aa5d96a75e1e7c95fc1cafc2688510efa24be85.png';
import { DeviceIconAbstract } from './DeviceIconAbstract';
import { DeviceIconBattery } from './DeviceIconBattery';

interface IconPreviewPageProps {
  onBack: () => void;
}

export function IconPreviewPage({ onBack }: IconPreviewPageProps) {
  return (
    <div className="flex flex-col h-full bg-[#f2f2f7]">
      {/* Header */}
      <div className="bg-white px-5 pt-4 pb-3 flex items-center gap-3 border-b border-black/[0.06]">
        <button
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-6 h-6" strokeWidth={2} />
        </button>
        <h1 className="text-[17px] font-semibold">Icon Preview</h1>
      </div>

      {/* Preview Content */}
      <div className="flex-1 overflow-y-auto px-5 py-8">
        <div className="space-y-8">
          {/* Title */}
          <div className="text-center">
            <h2 className="text-[20px] font-semibold text-[#1c1c1e] mb-2">
              Device Icon Comparison
            </h2>
            <p className="text-[15px] text-[#8e8e93]">
              Compare the original icon with the new abstract design
            </p>
          </div>

          {/* Original Icon Section */}
          <div className="bg-white rounded-[16px] p-6 shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-4">
              Original Icon
            </h3>
            <div className="space-y-6">
              {/* Size: 18px (current) */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div>
                  <p className="text-[15px] font-medium text-[#1c1c1e]">18×18 (Current)</p>
                  <p className="text-[13px] text-[#8e8e93]">Used in device status</p>
                </div>
                <img src={deviceIcon} alt="Device" className="w-[18px] h-[18px]" />
              </div>

              {/* Size: 32px */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div>
                  <p className="text-[15px] font-medium text-[#1c1c1e]">32×32</p>
                  <p className="text-[13px] text-[#8e8e93]">Medium size preview</p>
                </div>
                <img src={deviceIcon} alt="Device" className="w-[32px] h-[32px]" />
              </div>

              {/* Size: 48px */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div>
                  <p className="text-[15px] font-medium text-[#1c1c1e]">48×48</p>
                  <p className="text-[13px] text-[#8e8e93]">Large size preview</p>
                </div>
                <img src={deviceIcon} alt="Device" className="w-[48px] h-[48px]" />
              </div>
            </div>
          </div>

          {/* New Abstract Icon Section */}
          <div className="bg-white rounded-[16px] p-6 shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-4">
              New Abstract Icon
            </h3>
            <div className="space-y-6">
              {/* Size: 18px (current) */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div>
                  <p className="text-[15px] font-medium text-[#1c1c1e]">18×18 (Current)</p>
                  <p className="text-[13px] text-[#8e8e93]">Used in device status</p>
                </div>
                <DeviceIconAbstract className="w-[18px] h-[18px] opacity-60" />
              </div>

              {/* Size: 32px */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div>
                  <p className="text-[15px] font-medium text-[#1c1c1e]">32×32</p>
                  <p className="text-[13px] text-[#8e8e93]">Medium size preview</p>
                </div>
                <DeviceIconAbstract className="w-[32px] h-[32px] opacity-60" />
              </div>

              {/* Size: 48px */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div>
                  <p className="text-[15px] font-medium text-[#1c1c1e]">48×48</p>
                  <p className="text-[13px] text-[#8e8e93]">Large size preview</p>
                </div>
                <DeviceIconAbstract className="w-[48px] h-[48px] opacity-60" />
              </div>
            </div>
          </div>

          {/* Side by Side Comparison */}
          <div className="bg-white rounded-[16px] p-6 shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-4">
              Side by Side (18×18)
            </h3>
            <div className="flex items-center justify-center gap-12 py-8">
              <div className="text-center">
                <div className="w-20 h-20 bg-[#f2f2f7] rounded-xl flex items-center justify-center mb-3">
                  <img src={deviceIcon} alt="Device" className="w-[18px] h-[18px]" />
                </div>
                <p className="text-[13px] text-[#8e8e93]">Original</p>
              </div>
              <div className="text-center">
                <div className="w-20 h-20 bg-[#f2f2f7] rounded-xl flex items-center justify-center mb-3">
                  <DeviceIconAbstract className="w-[18px] h-[18px] opacity-60" />
                </div>
                <p className="text-[13px] text-[#8e8e93]">Abstract</p>
              </div>
            </div>
          </div>

          {/* Info */}
          <div className="bg-[#fff7ed] rounded-[16px] p-4 border border-[#fdba74]/30">
            <p className="text-[14px] text-[#3c3c43] leading-[1.5]">
              💡 <span className="font-medium">Tip:</span> The new abstract icon is vector-based (SVG), which means it scales perfectly at any size and adapts to different themes.
            </p>
          </div>

          {/* Battery Status Icons Section */}
          <div className="bg-white rounded-[16px] p-6 shadow-sm border-2 border-[#007aff]/20">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">
              Battery Status Colors
            </h3>
            <p className="text-[14px] text-[#8e8e93] mb-6">
              Icon color changes based on device battery level
            </p>
            
            <div className="space-y-4">
              {/* Full Battery - Green */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div className="flex items-center gap-3">
                  <DeviceIconBattery batteryLevel="full" className="w-[24px] h-[24px]" />
                  <div>
                    <p className="text-[15px] font-medium text-[#1c1c1e]">Full Battery</p>
                    <p className="text-[13px] text-[#8e8e93]">50% - 100%</p>
                  </div>
                </div>
                <div className="w-8 h-8 rounded-full bg-[#34c759] flex items-center justify-center">
                  <span className="text-[11px] font-semibold text-white">✓</span>
                </div>
              </div>

              {/* Medium Battery - Yellow */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div className="flex items-center gap-3">
                  <DeviceIconBattery batteryLevel="medium" className="w-[24px] h-[24px]" />
                  <div>
                    <p className="text-[15px] font-medium text-[#1c1c1e]">Medium Battery</p>
                    <p className="text-[13px] text-[#8e8e93]">20% - 49%</p>
                  </div>
                </div>
                <div className="w-8 h-8 rounded-full bg-[#ffb340] flex items-center justify-center">
                  <span className="text-[11px] font-semibold text-white">!</span>
                </div>
              </div>

              {/* Low Battery - Red */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div className="flex items-center gap-3">
                  <DeviceIconBattery batteryLevel="low" className="w-[24px] h-[24px]" />
                  <div>
                    <p className="text-[15px] font-medium text-[#1c1c1e]">Low Battery</p>
                    <p className="text-[13px] text-[#8e8e93]">0% - 19%</p>
                  </div>
                </div>
                <div className="w-8 h-8 rounded-full bg-[#ff3b30] flex items-center justify-center">
                  <span className="text-[11px] font-semibold text-white">⚠</span>
                </div>
              </div>

              {/* Disconnected - Gray */}
              <div className="flex items-center justify-between p-4 bg-[#f2f2f7] rounded-xl">
                <div className="flex items-center gap-3">
                  <DeviceIconBattery batteryLevel="disconnected" className="w-[24px] h-[24px]" />
                  <div>
                    <p className="text-[15px] font-medium text-[#1c1c1e]">Disconnected</p>
                    <p className="text-[13px] text-[#8e8e93]">No device connection</p>
                  </div>
                </div>
                <div className="w-8 h-8 rounded-full bg-[#8e8e93] flex items-center justify-center">
                  <span className="text-[11px] font-semibold text-white">—</span>
                </div>
              </div>
            </div>
          </div>

          {/* Battery Status in Different Sizes */}
          <div className="bg-white rounded-[16px] p-6 shadow-sm">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-4">
              Battery Status at Different Sizes
            </h3>
            
            {/* 18px size */}
            <div className="mb-6">
              <p className="text-[13px] text-[#8e8e93] mb-3">18×18 (Current size in app)</p>
              <div className="flex items-center gap-6 p-4 bg-[#f2f2f7] rounded-xl">
                <DeviceIconBattery batteryLevel="full" className="w-[18px] h-[18px]" />
                <DeviceIconBattery batteryLevel="medium" className="w-[18px] h-[18px]" />
                <DeviceIconBattery batteryLevel="low" className="w-[18px] h-[18px]" />
                <DeviceIconBattery batteryLevel="disconnected" className="w-[18px] h-[18px]" />
              </div>
            </div>

            {/* 32px size */}
            <div className="mb-6">
              <p className="text-[13px] text-[#8e8e93] mb-3">32×32</p>
              <div className="flex items-center gap-6 p-4 bg-[#f2f2f7] rounded-xl">
                <DeviceIconBattery batteryLevel="full" className="w-[32px] h-[32px]" />
                <DeviceIconBattery batteryLevel="medium" className="w-[32px] h-[32px]" />
                <DeviceIconBattery batteryLevel="low" className="w-[32px] h-[32px]" />
                <DeviceIconBattery batteryLevel="disconnected" className="w-[32px] h-[32px]" />
              </div>
            </div>

            {/* 48px size */}
            <div>
              <p className="text-[13px] text-[#8e8e93] mb-3">48×48</p>
              <div className="flex items-center gap-6 p-4 bg-[#f2f2f7] rounded-xl">
                <DeviceIconBattery batteryLevel="full" className="w-[48px] h-[48px]" />
                <DeviceIconBattery batteryLevel="medium" className="w-[48px] h-[48px]" />
                <DeviceIconBattery batteryLevel="low" className="w-[48px] h-[48px]" />
                <DeviceIconBattery batteryLevel="disconnected" className="w-[48px] h-[48px]" />
              </div>
            </div>
          </div>

          {/* Usage Example in Context */}
          <div className="bg-gradient-to-br from-[#f8f9fa] to-[#e9ecef] rounded-[16px] p-6 shadow-sm border border-black/[0.06]">
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-4">
              In Context: Top Bar Examples
            </h3>
            
            <div className="space-y-3">
              {/* Full battery example */}
              <div className="bg-white rounded-xl p-3 flex items-center gap-3">
                <button className="w-8 h-8 rounded-lg bg-white border border-black/[0.06] flex items-center justify-center shadow-sm">
                  <DeviceIconBattery batteryLevel="full" className="w-[18px] h-[18px]" />
                </button>
                <span className="text-[15px] text-[#3c3c43] font-medium">MemoPin</span>
                <span className="ml-auto text-[12px] text-[#34c759] font-medium">Connected</span>
              </div>

              {/* Medium battery example */}
              <div className="bg-white rounded-xl p-3 flex items-center gap-3">
                <button className="w-8 h-8 rounded-lg bg-white border border-black/[0.06] flex items-center justify-center shadow-sm">
                  <DeviceIconBattery batteryLevel="medium" className="w-[18px] h-[18px]" />
                </button>
                <span className="text-[15px] text-[#3c3c43] font-medium">MemoPin</span>
                <span className="ml-auto text-[12px] text-[#ffb340] font-medium">Battery 45%</span>
              </div>

              {/* Low battery example */}
              <div className="bg-white rounded-xl p-3 flex items-center gap-3">
                <button className="w-8 h-8 rounded-lg bg-white border border-black/[0.06] flex items-center justify-center shadow-sm">
                  <DeviceIconBattery batteryLevel="low" className="w-[18px] h-[18px]" />
                </button>
                <span className="text-[15px] text-[#3c3c43] font-medium">MemoPin</span>
                <span className="ml-auto text-[12px] text-[#ff3b30] font-medium">Low Battery 15%</span>
              </div>

              {/* Disconnected example */}
              <div className="bg-white rounded-xl p-3 flex items-center gap-3">
                <button className="w-8 h-8 rounded-lg bg-white border border-black/[0.06] flex items-center justify-center shadow-sm">
                  <DeviceIconBattery batteryLevel="disconnected" className="w-[18px] h-[18px]" />
                </button>
                <span className="text-[15px] text-[#3c3c43] font-medium">MemoPin</span>
                <span className="ml-auto text-[12px] text-[#8e8e93] font-medium">Not Connected</span>
              </div>
            </div>
          </div>

          {/* Color Psychology Info */}
          <div className="bg-[#e6f7ff] rounded-[16px] p-4 border border-[#91d5ff]/50">
            <p className="text-[14px] text-[#3c3c43] leading-[1.5] mb-2">
              🎨 <span className="font-medium">Color Psychology for ADHD Users:</span>
            </p>
            <ul className="text-[13px] text-[#6c6c70] space-y-1 ml-4">
              <li>• <span className="font-medium text-[#34c759]">Green</span> = Safe, no action needed</li>
              <li>• <span className="font-medium text-[#ffb340]">Yellow</span> = Awareness, but not urgent</li>
              <li>• <span className="font-medium text-[#ff3b30]">Red</span> = Action required soon</li>
              <li>• <span className="font-medium text-[#8e8e93]">Gray</span> = Neutral, inactive state</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
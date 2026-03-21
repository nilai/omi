import { ChevronLeft, Bluetooth, Battery, Signal, Zap, CheckCircle, AlertCircle, RefreshCw, Smartphone } from 'lucide-react';
import { useState, useEffect } from 'react';
import deviceIcon from 'figma:asset/8ac002bb09f248003898380b21e2cd719bfd8e6f.png';
import { DeviceIconBattery } from './DeviceIconBattery';

interface DeviceConnectionPageProps {
  onBack: () => void;
  onDeviceConnected?: (device: Device) => void;
  onDeviceDisconnected?: () => void;
  initialConnectedDevice?: Device | null;
}

interface Device {
  id: string;
  name: string;
  battery: number;
  signal: number;
  status: 'available' | 'connected' | 'connecting' | 'pairing';
  lastSeen?: string;
}

export function DeviceConnectionPage({ onBack, onDeviceConnected, onDeviceDisconnected, initialConnectedDevice }: DeviceConnectionPageProps) {
  const [isScanning, setIsScanning] = useState(true);
  const [devices, setDevices] = useState<Device[]>([]);
  const [connectedDevice, setConnectedDevice] = useState<Device | null>(initialConnectedDevice || null);
  const [connectingDeviceId, setConnectingDeviceId] = useState<string | null>(null);

  // Mock devices discovery
  useEffect(() => {
    if (isScanning) {
      const timer1 = setTimeout(() => {
        setDevices([
          {
            id: '1',
            name: 'MemoPin #4A2B',
            battery: 80,
            signal: 95,
            status: 'available',
            lastSeen: 'Just now'
          }
        ]);
      }, 1500);

      const timer2 = setTimeout(() => {
        setDevices(prev => [
          ...prev,
          {
            id: '2',
            name: 'MemoPin #7F8C',
            battery: 40,
            signal: 78,
            status: 'available',
            lastSeen: 'Just now'
          }
        ]);
      }, 2800);

      const timer3 = setTimeout(() => {
        setDevices(prev => [
          ...prev,
          {
            id: '3',
            name: 'MemoPin #1D9E',
            battery: 10,
            signal: 52,
            status: 'available',
            lastSeen: 'Just now'
          }
        ]);
        setIsScanning(false);
      }, 4200);

      return () => {
        clearTimeout(timer1);
        clearTimeout(timer2);
        clearTimeout(timer3);
      };
    }
  }, [isScanning]);

  const handleConnect = (device: Device) => {
    setConnectingDeviceId(device.id);
    
    // Simulate connection process
    setTimeout(() => {
      setDevices(prev => 
        prev.map(d => 
          d.id === device.id 
            ? { ...d, status: 'pairing' }
            : d
        )
      );

      setTimeout(() => {
        setDevices(prev => 
          prev.map(d => 
            d.id === device.id 
              ? { ...d, status: 'connected' }
              : { ...d, status: 'available' }
          )
        );
        setConnectedDevice(device);
        setConnectingDeviceId(null);
        if (onDeviceConnected) {
          onDeviceConnected(device);
        }
      }, 2000);
    }, 500);
  };

  const handleDisconnect = () => {
    if (connectedDevice) {
      setDevices(prev => 
        prev.map(d => 
          d.id === connectedDevice.id 
            ? { ...d, status: 'available' }
            : d
        )
      );
      setConnectedDevice(null);
      if (onDeviceDisconnected) {
        onDeviceDisconnected();
      }
    }
  };

  const handleRescan = () => {
    setIsScanning(true);
    setDevices([]);
    // Don't clear connectedDevice - keep the connection state
  };

  const getSignalColor = (signal: number) => {
    if (signal >= 80) return 'text-[#34c759]';
    if (signal >= 50) return 'text-[#ff9500]';
    return 'text-[#ff3b30]';
  };

  const getBatteryColor = (battery: number) => {
    if (battery >= 60) return 'from-[#34c759] to-[#28a745]';
    if (battery >= 30) return 'from-[#ff9500] to-[#ff8000]';
    return 'from-[#ff3b30] to-[#d32f2f]';
  };

  return (
    <div className="h-full flex flex-col bg-[#f2f2f7]">
      {/* Header */}
      <div className="px-5 pt-4 pb-3 flex items-center justify-between bg-[#f2f2f7] relative">
        <button 
          onClick={onBack}
          className="text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <ChevronLeft className="w-5 h-5" strokeWidth={2.5} />
        </button>
        <h1 className="text-[17px] font-semibold text-[#1c1c1e] absolute left-1/2 transform -translate-x-1/2">
          Connect Device
        </h1>
        <button 
          onClick={handleRescan}
          className="flex items-center gap-1.5 text-[#007aff] hover:opacity-70 transition-opacity"
        >
          <RefreshCw className={`w-4.5 h-4.5 ${isScanning ? 'animate-spin' : ''}`} strokeWidth={2.5} />
          <span className="text-[15px] font-medium">Scan</span>
        </button>
      </div>

      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto px-5 pb-24">
        
        {/* Scanning Animation - Always at top */}
        {isScanning && (
          <div className="mt-4 mb-8 flex flex-col items-center">
            <div className="relative w-32 h-32 mb-6">
              {/* Ripple animations */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="absolute w-32 h-32 rounded-full bg-[#007aff]/10 animate-ping" style={{ animationDuration: '2s' }}></div>
                <div className="absolute w-24 h-24 rounded-full bg-[#007aff]/20 animate-ping" style={{ animationDuration: '2s', animationDelay: '0.5s' }}></div>
                <div className="absolute w-16 h-16 rounded-full bg-[#007aff]/30 animate-ping" style={{ animationDuration: '2s', animationDelay: '1s' }}></div>
              </div>
              {/* Center icon - Product Image */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="w-20 h-20 rounded-full bg-white flex items-center justify-center shadow-lg overflow-hidden">
                  <img src={deviceIcon} alt="MemoPin" className="w-full h-full object-cover scale-110 animate-pulse" />
                </div>
              </div>
            </div>
            <h3 className="text-[17px] font-semibold text-[#1c1c1e] mb-2">Scanning for Devices</h3>
            <p className="text-[14px] text-[#8e8e93] text-center max-w-xs">
              Make sure your MemoPin is turned on and within range
            </p>
          </div>
        )}

        {/* Connected Device Section */}
        {connectedDevice && (
          <div className={`${isScanning ? 'mt-0' : 'mt-4'} mb-6`}>
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">Connected Device</h3>
            <div className="bg-white rounded-[16px] p-5 shadow-sm border border-black/[0.06]">
              <div className="flex items-center gap-4 mb-4">
                {/* Product image */}
                <div className="w-14 h-14 rounded-full bg-white flex items-center justify-center shadow-md flex-shrink-0 relative overflow-hidden">
                  <img src={deviceIcon} alt={connectedDevice.name} className="w-full h-full object-cover scale-110" />
                  {/* Connected status indicator */}
                  <div className="absolute -top-0.5 -right-0.5 w-6 h-6 bg-[#34c759] rounded-full border-2 border-white flex items-center justify-center shadow-md">
                    <CheckCircle className="w-3.5 h-3.5 text-white" strokeWidth={3} />
                  </div>
                </div>
                <div className="flex-1 space-y-2">
                  <h3 className="text-[16px] font-semibold text-[#1c1c1e]">{connectedDevice.name}</h3>
                  {/* Battery Bar */}
                  <div className="flex items-center gap-3">
                    <Battery className="w-4 h-4 text-[#8e8e93] flex-shrink-0" strokeWidth={2} />
                    <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                      <div 
                        className={`h-full bg-gradient-to-r ${getBatteryColor(connectedDevice.battery)} rounded-full transition-all duration-500`}
                        style={{ width: `${connectedDevice.battery}%` }}
                      />
                    </div>
                    <span className="text-[13px] text-[#8e8e93] font-medium w-10 text-right">{connectedDevice.battery}%</span>
                  </div>
                </div>
              </div>
              <button
                onClick={handleDisconnect}
                className="w-full py-2.5 bg-[#f2f2f7] rounded-[10px] text-[#ff3b30] font-semibold hover:bg-[#e5e5ea] transition-colors"
              >
                Disconnect
              </button>
            </div>
          </div>
        )}

        {/* Available Devices Section */}
        {devices.length > 0 && (
          <div className="mt-6">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-2 px-1">{connectedDevice ? 'Other Devices' : 'Available Devices'}</h3>
            <div className="bg-white rounded-[16px] overflow-hidden shadow-sm border border-black/[0.06]">
              {devices.filter(device => device.id !== connectedDevice?.id).map((device, index, filteredDevices) => {
                return (
                  <div 
                    key={device.id}
                    className={`px-5 py-4 ${index !== filteredDevices.length - 1 ? 'border-b border-black/[0.06]' : ''}`}
                  >
                    <div className="flex items-center gap-4 mb-3">
                      {/* Product image with battery status color */}
                      <div className="w-14 h-14 rounded-full bg-white flex items-center justify-center shadow-md flex-shrink-0 relative overflow-hidden">
                        <img src={deviceIcon} alt={device.name} className="w-full h-full object-cover scale-110" />
                      </div>
                      <div className="flex-1 space-y-2">
                        <h3 className="text-[16px] font-semibold text-[#1c1c1e]">{device.name}</h3>
                        {/* Battery Bar */}
                        <div className="flex items-center gap-3">
                          <Battery className="w-4 h-4 text-[#8e8e93] flex-shrink-0" strokeWidth={2} />
                          <div className="flex-1 h-2 bg-[#f2f2f7] rounded-full overflow-hidden">
                            <div 
                              className={`h-full bg-gradient-to-r ${getBatteryColor(device.battery)} rounded-full transition-all duration-500`}
                              style={{ width: `${device.battery}%` }}
                            />
                          </div>
                          <span className="text-[13px] text-[#8e8e93] font-medium w-10 text-right">{device.battery}%</span>
                        </div>
                      </div>
                    </div>

                    {/* Connect Button */}
                    {device.status === 'available' && (
                      <button
                        onClick={() => handleConnect(device)}
                        disabled={connectingDeviceId !== null}
                        className="w-full py-2.5 bg-[#007aff] rounded-[10px] text-white font-semibold hover:bg-[#0051d5] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      >
                        Connect
                      </button>
                    )}

                    {device.status === 'connecting' && (
                      <div className="w-full py-2.5 bg-[#007aff]/10 rounded-[10px] text-[#007aff] font-semibold flex items-center justify-center gap-2">
                        <RefreshCw className="w-4 h-4 animate-spin" strokeWidth={2.5} />
                        Connecting...
                      </div>
                    )}

                    {device.status === 'pairing' && (
                      <div className="w-full py-2.5 bg-[#007aff]/10 rounded-[10px] text-[#007aff] font-semibold flex items-center justify-center gap-2">
                        <RefreshCw className="w-4 h-4 animate-spin" strokeWidth={2.5} />
                        Pairing...
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* Connection Tips */}
        {!isScanning && devices.length > 0 && (
          <div className="mt-8 px-1">
            <h3 className="text-[13px] font-semibold text-[#8e8e93] uppercase tracking-wide mb-3">Connection Tips</h3>
            <div className="space-y-3">
              <div className="flex gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8e8e93] mt-1.5 flex-shrink-0"></div>
                <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                  Keep your device within 30 feet (10 meters) for optimal connection
                </p>
              </div>
              <div className="flex gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8e8e93] mt-1.5 flex-shrink-0"></div>
                <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                  Ensure your MemoPin is fully charged for the best performance
                </p>
              </div>
              <div className="flex gap-3">
                <div className="w-1.5 h-1.5 rounded-full bg-[#8e8e93] mt-1.5 flex-shrink-0"></div>
                <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                  If you're having trouble connecting, try restarting your MemoPin
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Troubleshooting */}
        {!isScanning && devices.length === 0 && !connectedDevice && (
          <div className="mt-8">
            <div className="bg-white rounded-[16px] p-5 shadow-sm border border-black/[0.06]">
              <div className="flex items-start gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-[#ff9500]/10 flex items-center justify-center flex-shrink-0">
                  <AlertCircle className="w-5 h-5 text-[#ff9500]" strokeWidth={2} />
                </div>
                <div>
                  <h3 className="text-[16px] font-semibold text-[#1c1c1e] mb-1">No Devices Found</h3>
                  <p className="text-[14px] text-[#8e8e93] leading-relaxed">
                    We couldn't find any MemoPin devices nearby. Try the following:
                  </p>
                </div>
              </div>
              <div className="space-y-3 ml-13">
                <div className="flex gap-3">
                  <span className="text-[14px] text-[#007aff] font-semibold flex-shrink-0">1.</span>
                  <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                    Make sure your MemoPin is powered on
                  </p>
                </div>
                <div className="flex gap-3">
                  <span className="text-[14px] text-[#007aff] font-semibold flex-shrink-0">2.</span>
                  <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                    Check that Bluetooth is enabled on your phone
                  </p>
                </div>
                <div className="flex gap-3">
                  <span className="text-[14px] text-[#007aff] font-semibold flex-shrink-0">3.</span>
                  <p className="text-[14px] text-[#3c3c43] leading-relaxed">
                    Move closer to your device and tap "Scan" again
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Help Section */}
        <div className="mt-8 mb-6">
          <div className="bg-[#007aff]/5 rounded-[16px] p-5 border border-[#007aff]/10">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 rounded-full bg-[#007aff] flex items-center justify-center flex-shrink-0">
                <Smartphone className="w-4 h-4 text-white" strokeWidth={2.5} />
              </div>
              <div>
                <h3 className="text-[15px] font-semibold text-[#1c1c1e] mb-1">Need Help?</h3>
                <p className="text-[13px] text-[#3c3c43] leading-relaxed mb-3">
                  Visit our support page for detailed setup instructions and troubleshooting guides.
                </p>
                <button className="text-[14px] text-[#007aff] font-semibold hover:opacity-70 transition-opacity">
                  Open Support →
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
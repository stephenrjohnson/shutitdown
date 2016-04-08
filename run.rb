require 'rubygems'
require 'time'
require 'bundler/setup'
require 'dbus'
require 'libusb'

VENDOR=0x17ef
PRODUCT=0x100f
SERVICE='com.ubuntu.Upstart'
OBJECT='/com/ubuntu/Upstart'
IFACE='com.ubuntu.Upstart0_6'

trap("INT") {
  puts "Quitting..."
  halter.quit
  main.quit
  exit
}

armed = false
halt = false

def shutitdown
  puts 'Shut it down bro'
end

halter = Thread.new do
 puts 'Running backgroup checker'
 while true do 
   usb1 = LIBUSB::Context.new
   dockcheck = usb1.devices(:idVendor => VENDOR, :idProduct => PRODUCT).first
   sleep 1
   if (armed == true) && (dockcheck.nil? == true)
     shutitdown
   end
  end
end

halter.run

bus   = DBus.session_bus
saver = bus.service(SERVICE).object(OBJECT)
saver.introspect
saver.default_iface =IFACE
saver.on_signal("EventEmitted") do |state|
  usb2 = LIBUSB::Context.new
  dock = usb2.devices(:idVendor => VENDOR, :idProduct => PRODUCT).first
  if state == 'desktop-lock'
    if dock.nil?
      armed = false
    else 
      armed = true
    end
    puts "[#{ Time.now } ] Screensaver has been #{ state }. Device armed #{armed}"
  elsif state == 'desktop-unlock'
    armed = false
    puts "[#{ Time.now } ] Screensaver has been #{ state }. Device armed #{armed}"
  end
end

main = DBus::Main.new
main << bus
puts 'Running dbus listener'
main.run

require 'rubygems'
require 'time'
require 'bundler/setup'
require 'dbus'
require 'libusb'
require 'yaml'
CONFIG = YAML.load(File.read('config.yml'))

trap('INT') do
  puts 'Quitting...'
  halter.quit
  main.quit
  exit
end

armed = false
halt = false

def shutitdown
  puts 'Shut it down bro'
end

halter = Thread.new do
  loop do
    usb1 = LIBUSB::Context.new
    dockcheck = usb1.devices(idVendor: CONFIG['DOCK']['VENDOR'], idProduct: CONFIG['DOCK']['PRODUCT']).first
    sleep 1
    shutitdown if (armed == true) && (dockcheck.nil? == true)
  end
end

bus   = DBus.session_bus
saver = bus.service(CONFIG['DBUS']['SERVICE']).object(CONFIG['DBUS']['OBJECT'])
saver.introspect
saver.default_iface = CONFIG['DBUS']['IFACE']
saver.on_signal('EventEmitted') do |state|
  usb2 = LIBUSB::Context.new
  dock = usb2.devices(idVendor: CONFIG['DOCK']['VENDOR'], idProduct: CONFIG['DOCK']['PRODUCT']).first
  if state == CONFIG['DBUS']['LOCKSTATE']
    armed = if dock.nil?
              false
            else
              true
            end
    puts "[#{Time.now} ] Screensaver has been #{state}. Device armed #{armed}"
  elsif state == CONFIG['DBUS']['UNLOCKSTATE']
    armed = false
    puts "[#{Time.now} ] Screensaver has been #{state}. Device armed #{armed}"
  end
end

listen = DBus::Main.new
listen << bus
puts 'Running backgroup checker'
halter.run
puts 'Running dbus listener'
listen.run

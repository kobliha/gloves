#--
# Config Agents Framework
#
# Copyright (C) 2011 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 or version 3 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++

require "rubygems"
require "dbus"
require "dbus_clients/backend_exception"

module DbusClients
  class ScriptClient
    SCRIPT_INTERFACE = "org.opensuse.config_agent.script"
    def self.agent_id(value=nil)
      instance_eval "def filename_for_service() \"#{value}\" end" if value #FIXME escape VALUE!!
      raise "File service doesn't define value its file name" unless respond_to? :filename_for_service
      filename_for_service
    end

    def self.execute (options)
      ret = if Process.euid == 0 #root user
          Utils.direct_call self.name, :execute, options
        else
          dbus_object.execute(options).first #ruby dbus return array of return values
        end
      if ret["error"]
        if ret["error_type"]
          BackendException.raise_from_hash ret
        else
          raise BackendException.new(ret["error"],ret["backtrace"])
        end
      end
      return ret
    end

    def self.service_name
      "org.opensuse.config_agent.script.#{agent_id}" #TODO check filename characters
    end

    def self.object_path
      "/org/opensuse/config_agent/script/#{agent_id}" #TODO check filename characters
    end
  private
    def self.dbus_object
      bus = DBus::SystemBus.instance
      rb_service = bus.service service_name
      instance = rb_service.object object_path
      instance.introspect #to get interfaces
      iface = instance[SCRIPT_INTERFACE]
    end
  end
end

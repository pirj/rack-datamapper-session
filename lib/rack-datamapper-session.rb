require 'rack/session/abstract/id'

module Rack
  module Session
    class DataMapperSession
      include DataMapper::Resource

      property :id, Serial
      property :sid, String, :length => 128
      property :data_object, Object
      
      def [] key
        data[key]
      end
      
      def []= key, value
        data[key] = value
      end
      
      def data
        self.data_object ||= {}
      end
      
      def data= new_data
        self.data_object = new_data
      end
    end
    
    class DataMapper < Abstract::ID
      def get_session(env, sid)
        session = DataMapperSession.first(:sid => sid) if sid

        unless sid and session
          env['rack.errors'].puts("Session '#{sid.inspect}' not found, initializing...") if $VERBOSE and not sid.nil?
          sid = generate_sid
          session = DataMapperSession.new(:sid => sid)
          raise 'Unable to store session' unless session.save
        end

        # !!! check expiry
        return [sid, session]
      end

      def set_session(env, sid, new_session, options)
        expiry = options[:expire_after]
        expiry = expiry.nil? ? 0 : expiry + 1

        session = DataMapperSession.first(:sid => sid) if sid

        if options[:renew] or options[:drop]
          session.destroy
          return false if options[:drop]
          sid = generate_sid
          session = DataMapperSession.new(:sid => sid)
        end
        
        session.data = new_session.data
        raise 'Unable to update session' unless session.save

        return sid
      end
    end
  end
end

class ConnectionManager
  class << self
    # new_connection: Yeni bağlantı durumunda 'connections' key'ini arttır.
    #
    # NOTE: ActionCable için '2' nolu db kullanılmaktadır.
    #
    # Usage:
    #
    #   $ redis-cli -n 2
    #   > KEYS *
    #   'connections'
    #   ...
    #   > GET "connections"
    #   '2'
    #   > INCR "connections"
    #   (integer) 3
    def new_connection
      redis.incr "connections"
      trigger_callbacks
    end

    # connection_gone: Bağlantı sonlandırılınca 'connections' key'ini azalt.
    def connection_gone
      redis.decr "connections"
      trigger_callbacks
    end

    def connected_count
      redis.get "connections" || 0
    end

    # register_callback: Bağlı kişileri canlı izlemek isteyenleri (NotificationChannel)
    # kaydet. Her bir bağlantı için thread oluştur.
    def register_callback(callback)
      mutex.synchronize do
        callbacks.push(callback)
      end
    end

    # deregister_callback: Üyelik sonlandırıldığında thread'i kaldır.
    def deregister_callback(callback)
      mutex.synchronize do
        callbacks.delete(callback)
      end
    end

    private
    def redis
      @redis ||= Redis.new(url: Rails.application.config_for(:cable)['url'])
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def callbacks
      @callbacks ||= []
    end

    # trigger_callbacks: Tüm bağlantı sahiplerini haberdar et (broadcast).
    #
    # Usage:
    #
    #   class EventsChannel < ApplicationCable::Channel
    #     def stream_live_count
    #       ConnectionManager.register_callback broadcast_to_current_connection_proc
    #       ...
    #     end
    #
    #     private
    #     def broadcast_to_current_connection_proc
    #       @proc ||= Proc.new do
    #         ActionCable.server.broadcast current_connection_stream, payload
    #       end
    #     end
    #   end
    def trigger_callbacks
      callbacks.each { |callback| callback.call }
    end
  end
end

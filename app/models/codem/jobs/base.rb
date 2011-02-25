module Codem
  module Jobs
    class Base
      include HTTParty
      format :json

      def self.remove_all_for(job)
        Delayed::Job.all.each do |delayed_job|
          delayed_job.destroy if delayed_job.payload_object.job == job
        end
      end
      
      attr_accessor :job, :parameters

      def initialize(job=nil, parameters={})
        @job        = job
        @parameters = parameters
      end
      
      def job_status(job)
        self.class.get("#{job.host.address}/jobs/#{job.remote_jobid}")
      end
      
      def display_name
        self.class.name.demodulize
      end
      
      def reschedule(options={})
        Delayed::Job.enqueue self.class.new(job, parameters), options
      end
      
      def error(delayed_job, exception)
        if exception.is_a?(Errno::ECONNREFUSED)
          job.enter(:on_hold)
        end
      end
      
      def failure
        reschedule
      end
    end
  end
end
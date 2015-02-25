require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Starmade < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your logstash config.
  #
  # filter {
  #   starmade { ... }
  # }
  config_name "starmade"

  # New plugins should start life at milestone 1.
  milestone 1

  # Replace the message with this value.
  config :message, :validate => :string

  public
  def register
    # nothing to do
  end # def register

  public
  def filter(event)
    # return nothing unless there's an actual filter event
    return unless filter?(event)
    if @message
      # Replace the event message with our message as configured in the
      # config file.
      firstSlice = event["message"].match("^\\[(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\] (.*)")
      event["stamp"] = firstSlice[1]
      # do we have a second tag?
      secondSlice = firstSlice[2].match("^\\[(.*?)\\]\\s*(.*)")
      if secondSlice
        event["type"] = secondSlice[1]
        thirdSlice = secondSlice[2].match("^\\[(.*?)\\]\\s*(.*)")
        if thirdSlice
          event["subtype"] = thirdSlice[1]
          event["message"] = thirdSlice[2]
        else
          event["message"] = secondSlice[2]  
        end
      else
        event["type"] = "generic"
        event["message"] = firstSlice[2]
      end
      #event["message"] = @message      
    end
    # filter_matched should go in the last line of our successful code 
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Foo
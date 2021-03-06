class StaticController < ApplicationController
	
  skip_before_filter :authenticate_user!
  
  Message = Struct.new(:subject, :body, :reply_to)

  def home
    # flash[:alert] ="Alert me!"
    # flash[:notice] ="Notice me!"
    # flash[:warning] ="Warn me!"
    # flash[:success] ="Success me!"
    # flash[:error] ="Error me!"
	end

  def about
    @message= Message.new("", "", "");
  end  

  def message_to_admin
    @message=Message.new(params[:message][:subject], params[:message][:body], params[:message][:reply_to])
    RybickaMailer.message_to_admin(@message, current_user).deliver_now
    flash[:notice]=t("rybickazlata.static.contact_us.message.to_admin.sent")
    @message= Message.new("", "", "");
    redirect_to about_url
  end  

  def change_locale
    redirect_to localize_referer(params[:locale])
  end  

  private

  def localize_referer(new_locale)
    reff=request.referer
    
    if (RybickaZlata4::Application.available_locales.map {|ls| ls.last}).include?(new_locale.to_s)
      if reff.present? 
        if reff.include?("?")
          if reff.match(/locale=[a-z]*/)
            reff= reff.gsub(/locale=[a-z]*/,"locale=#{new_locale}" )
          else  
            reff= reff+"\&locale=#{new_locale}"
          end
        else
          reff= reff+"?locale=#{new_locale}"     
        end
      else
        reff= root_path
      end  
    else  
      reff=reff.present? ? reff : root_path
    end 

    reff
  end 

end

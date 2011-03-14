class PeopleNetworkRequestsController < ApplicationController
  before_filter :authenticate_user!

  def create
    @trusted_person = Person.find(params[:trusted_person_id])
    if @trusted_person.request_trusted_relationship(current_user.person)
      redirect_to(@trusted_person, :notice => I18n.t('messages.people.requested_trusted_relationship'))
    else
      # TODO: handle this better (should not happen)
      redirect_to(@trusted_person)
    end  
  end
  
  def destroy
    people_network_request = PeopleNetworkRequest.find(params[:id])
    trusted_person = people_network_request.trusted_person
    people_network_request.destroy
    redirect_to(trusted_person, :notice => I18n.t('messages.people.cancel_requested_trusted_relationship'))
  end
end
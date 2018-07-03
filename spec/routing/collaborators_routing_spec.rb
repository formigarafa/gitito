require 'spec_helper'

describe CollaboratorsController do
  describe 'routing' do
    it 'routes to #create' do
      post('/repositories/2/collaborators').should route_to('collaborators#create', repository_id: '2')
    end

    it 'routes to #destroy' do
      delete('/repositories/3/collaborators/1').should route_to('collaborators#destroy', id: '1', repository_id: '3')
    end
  end
end

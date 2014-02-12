module TheComments
  class UserRoutes
    def call mapper, options = {}
      mapper.collection do
        mapper.post :create
      end

      mapper.member do
        mapper.get   :edit
        mapper.patch :update
        mapper.put   :update
      end
    end
  end

  class AdminRoutes
    def call mapper, options = {}
      mapper.member do
        mapper.patch :to_published
        mapper.patch :to_deleted
        mapper.patch :to_draft
        mapper.patch :to_spam
      end
      mapper.collection do
        mapper.get :index
        mapper.get :total_published
        mapper.get :total_deleted
        mapper.get :total_spam
      end
    end
  end
end
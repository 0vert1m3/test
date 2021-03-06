module Keys
  class DestroyService < ::Keys::BaseService
    prepend EE::Keys::DestroyService

    def execute(key)
      key.destroy if destroy_possible?(key)
    end

    # overriden in EE::Keys::DestroyService
    def destroy_possible?(key)
      true
    end
  end
end

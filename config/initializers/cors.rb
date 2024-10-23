Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # This is the list of authorized origin which can do CORS to the API.
    # rack-cors will setup the appropriate headers ;)
    origins (/\Ahttp:\/\/localhost(:\d+)?\z/),
            'https://grid5000.gitlabpages.inria.fr',
            'https://public-api-devel.grid5000.fr',
            'https://public-api.grid5000.fr',
            'https://api.grid5000.fr'
    resource '*', headers: :any, methods: [:get, :post], credentials: true
  end
end

# gsecretR

An R package for interfacing with Google Cloud Secret Manager.

If you dont have the devtools package installed, you need to install
it now 
```
install.packages('devtools')
```
Then you can install gsecretR.
```
devtools::install_github('episphere/gsecretR')
```

in order to use it, you will need to GCP resources and an oauth app.  
I dont set a default app like bigrquery so if you dont have an app
and are used to using the default app.  Initialize the app using

```
library(gsecretR)
gsecret_auth_config(gargle::gargle_app())
```

However, using the gargle_app is discourage and the gargle developers
may remove the app or rotate the values.

To set a secret:

``
gsecret::set_secret(project_id="<project>",secret_id="<string>",secret="<the secret>")
secret = gsecret::get_secret_version(project_id="<project>",secret_id="<string>")
``

You can get an old version of the secret by adding `version="version"` as a parameter.  
The version ids can be obtain from the google console.  I'm looking to see if the APIs
allow listing versions.

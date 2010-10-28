core = "6.x"
api = "2"

; include Pressflow core
includes[pressflow] = "http://github.com/ergonlogic/Makefiles/raw/master/el_pressflow.make"

; get profile from github
projects[feature_server][type] = "profile"
projects[feature_server][download][type] = "git"
projects[feature_server][download][url] = "git://git.github.com/ergonlogic/el_tattler/tattler.profile"

; module dependencies

projects[] = admin
projects[] = admin_menu
projects[] = block_ie6
projects[] = buzzmonitor
projects[] = cck
projects[] = charts_graphs
projects[] = custompage
projects[] = date
projects[] = devel
projects[] = distro
projects[] = feedapi
projects[] = feedapi_dedupe
projects[] = feedapi_itemfilter
projects[] = flag
projects[] = imageapi
projects[] = imagecache
projects[] = install_profile_api
projects[] = logintoboggan
projects[] = opencalais
projects[] = plus1
projects[] = rdf
projects[] = search_config
projects[] = swfobject_api
projects[] = tagadelic
projects[] = tattlerapp
projects[] = tokenauth
projects[] = views
projects[] = views_charts
projects[] = views_groupby
projects[] = votingapi

; theme dependencies
projects[] = tattler_theme
projects[] = rootcandy

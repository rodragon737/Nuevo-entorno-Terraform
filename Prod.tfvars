resource_group  = "RG"
this_location   = "eastus"
enviroment      = "test"
network         = "10.99.10.0/24"
subnet          = "10.99.10.0/25"
dns1            = "10.200.10.10"
dns2            = "8.8.8.8"
win_privateip   = "10.99.10.10"
## Clean-->
admin_sql_pass  = "PassS8L!!"
admin_sql_user  = "AdminSQL"
##<-- Clean
lb_probe        = {
    "https_probe" = {
            name                = "HP-HTTPS"
            protocol            = "Tcp"
            port                = 443
            interval_in_seconds = 5
            number_of_probes    = 2
    },
    "http_probe" = {
            name                = "HP-HTTP"
            protocol            = "Tcp"
            port                = 80
            interval_in_seconds = 5
            number_of_probes    = 2
    }
}
databases       = {
    "db_test"   = {
            name                = "Test"
    },
    "db_live"   = {
            name                = "Live"
    }
}

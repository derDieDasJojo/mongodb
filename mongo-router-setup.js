print("use database:"+ stackname)
use stackname
print("create user:"+admin-user)
db.createUser( { user: admin-user,
                 pwd: admin-password,
                 roles: [ { "dbOwner"] } )


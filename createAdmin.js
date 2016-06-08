print("create user " + adminuser);
db.createUser( { user: adminuser,
                 pwd: adminpassword,
                 roles: [  
			"dbOwner"
			] 
             } );

print("create user clusterAdmin");
db.createUser( { user: "clusterAdmin",
                 pwd: clusteradminpassword,
                 roles: [  
			{ role: "root", db: "admin" }
			] 
             } );

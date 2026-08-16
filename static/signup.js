document.getElementById("signupForm").addEventListener("submit", function(e){

e.preventDefault();

const data = {
first_name: document.getElementById("first_name").value,
last_name: document.getElementById("last_name").value,
department: document.getElementById("department").value,
email: document.getElementById("email").value,
password: document.getElementById("password").value
};

fetch("/signup",{
method:"POST",
headers:{
"Content-Type":"application/json"
},
body:JSON.stringify(data)
})
.then(res=>res.json())
.then(data=>{
alert(data.message);
});

});
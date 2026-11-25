
const loginForm = document.getElementById("loginForm");
const passwordInput = document.getElementById("password");
const showPassword = document.getElementById("showPassword");
const message = document.getElementById("message");

if (showPassword) {
    showPassword.addEventListener("change", function () {
        passwordInput.type = this.checked ? "text" : "password";
    });
}

if (loginForm) {
    loginForm.addEventListener("submit", function (event) {
        event.preventDefault();

        const email = document.getElementById("email").value.trim();
        const password = passwordInput.value;

        message.textContent = "";
        message.style.color = "red";

        if (!email || !password) {
            message.textContent = "Please fill all fields.";
            return;
        }

        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            message.textContent = "Please enter a valid email.";
            return;
        }

        message.textContent =
            "Form validation successful. Backend login connection is pending.";
        message.style.color = "green";
    });
}

const forgotPassword = document.getElementById("forgotPassword");

if (forgotPassword) {
    forgotPassword.addEventListener("click", function (event) {
        event.preventDefault();
        alert("Please contact the administrator for password recovery.");
    });
}

const registerForm = document.getElementById("registerForm");

if (registerForm) {
    const registerMessage = document.getElementById("message");

    registerForm.addEventListener("submit", async function(event) {
    event.preventDefault();

    const name = document.getElementById("name").value.trim();
    const email = document.getElementById("email").value.trim();
    const password = document.getElementById("password").value;
    const confirmPassword = document.getElementById("confirmPassword").value;

    registerMessage.textContent = "";
    registerMessage.style.color = "red";

    if (!name || !email || !password || !confirmPassword) {
        registerMessage.textContent = "Please fill all fields.";
        return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        registerMessage.textContent = "Invalid email address.";
        return;
    }

    if (password.length < 8) {
        registerMessage.textContent = "Password must contain at least 8 characters.";
        return;
    }

    if (password !== confirmPassword) {
        registerMessage.textContent = "Passwords do not match.";
        return;
    }

    try {
        const response = await fetch("http://127.0.0.1:5000/api/auth/register", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                name: name,
                email: email,
                password: password
            })
        });

        const result = await response.json();

        if (!response.ok) {
            registerMessage.textContent = result.message || "Registration failed.";
            return;
        }

        registerMessage.style.color = "green";
        registerMessage.textContent = "Registration successful!";

    } catch (error) {
        registerMessage.textContent = "Cannot connect to the server.";
    }
});
}

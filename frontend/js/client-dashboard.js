
document.addEventListener("DOMContentLoaded", function () {

    // Highlight dashboard navigation links
    const navLinks = document.querySelectorAll(".sidebar nav a");

    navLinks.forEach(function (link) {
        link.addEventListener("click", function () {
            navLinks.forEach(item => item.classList.remove("active"));
            this.classList.add("active");
        });
    });

    // Display logged-in client information
    const userInfo = document.querySelector(".user-info");

    const savedName = localStorage.getItem("clientName");

    if (savedName && userInfo) {
        userInfo.textContent = savedName;
    }

});

$(document).ready(function () {
	$("#header").load("common/header.html"); 
	$("#menu").load("common/menu.html", function(){
		$("#btn_about").click(function(){
			event.preventDefault();
			goAboutMe();
		});
		
		$("#btn_personal_projects").click(function(){
			event.preventDefault();
			$(".nav-link").removeClass("active");
			$(this).addClass("active");
			$("#divMainContent").load("personal_projects.html", function(){
				personalProjectsEvents();
			});
		});
		
		$("#btn_pills").click(function(){
			event.preventDefault();
			$(".nav-link").removeClass("active");
			$(this).addClass("active");
			$("#divMainContent").load("pills.html", function(){
				pillsEvents();
			});
		});
		
		$("#btn_work_projects").click(function(){
			event.preventDefault();
			$(".nav-link").removeClass("active");
			$(this).addClass("active");
			$("#divMainContent").load("work_projects.html", function(){
				workProjectsEvents();
			});
		});
	});
	
	$("#divMainContent").load("about.html");
		
	document.getElementById("year_footer").innerHTML = new Date().getFullYear();
});

function goAboutMe(){
	$(".nav-link").removeClass("active");
	$("#btn_about").addClass("active");
	$("#divMainContent").load("about.html");
}
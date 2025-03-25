const isMobile = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
var personalProjects = null;
var workProjects = null;
var pills = null;
var itemsPerPage = 0;
var personalProjectsTotalPages = 0;
var workProjectsTotalPages = 0;
var pillsTotalPages = 0;
var currentMenuTab = "about_me";
$(function(){
	fetch('static/data/work_projects.json').then((response) => response.json()).then((json) => {
		workProjects = json;
		itemsPerPage = 9;
		workProjectsTotalPages = Math.ceil(workProjects.length / itemsPerPage) == 0 ? 1 : Math.ceil(workProjects.length / itemsPerPage);
	});
	fetch('static/data/personal_projects.json').then((response) => response.json()).then((json) => {
		personalProjects = json;
		itemsPerPage = 9;
		personalProjectsTotalPages = Math.ceil(personalProjects.length / itemsPerPage) == 0 ? 1 : Math.ceil(personalProjects.length / itemsPerPage);
	});
	fetch('static/data/pills.json').then((response) => response.json()).then((json) => {
		pills = json;
		itemsPerPage = 12;
		pillsTotalPages = Math.ceil(pills.length / itemsPerPage) == 0 ? 1 : Math.ceil(pills.length / itemsPerPage);
	});
});
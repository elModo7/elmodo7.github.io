var personalProjectsPage = 0;

function personalProjectsEvents(){
	unbindEvents();
	var itemsPerRow = 4;
	itemsPerPage = 12;
	var personalProjectsHTML = '';
	var cntKeys = 0;
	for (const [key, value] of Object.entries(personalProjects.slice(personalProjectsPage * itemsPerPage, personalProjectsPage * itemsPerPage + itemsPerPage))) {
		if(cntKeys == itemsPerPage){
			break;
		}
		if(key % itemsPerRow == 0){
			personalProjectsHTML += '<div class="row mt-4">';
		}
		personalProjectsHTML += '<div class="col-sm-3">';
		for (const [keyBadge, valueBadge] of Object.entries(value.badges)) {
			personalProjectsHTML +=	'<span class="badge ' + valueBadge.color + '">' + valueBadge.name + '</span> ';
		}
		personalProjectsHTML += '<span class="badge"> </span>'; // Needed for frame possition
		personalProjectsHTML += '<a ' + (value.url == '' ? '' : ('href="' + value.url + '" target="_blank"')) + ' class="link article-link" article="' + value.page + '"><div class="position-relative">';
		if(value.ribbon.color && value.ribbon.name){
			personalProjectsHTML +=	'<img src="' + value.img + '" alt="Photo 1" class="img-fluid">';
			personalProjectsHTML +=	'<div class="ribbon-wrapper ribbon-lg">';
		}
		personalProjectsHTML +=	'<div class="ribbon ' + value.ribbon.color + ' text-lg">' + value.ribbon.name + '</div></div>';
		personalProjectsHTML += '<h3 style="text-align:center">' + value.title + '</h3><p style="text-align:center">' + value.description + '</p></div></a></div>';
		if((key + 1) % itemsPerRow == 0 || cntKeys + 1 == itemsPerPage || cntKeys + 1 == personalProjects.length){
			personalProjectsHTML += '</div>';
		}
		cntKeys++;
	}
	
	if(personalProjects.length > itemsPerPage){
		personalProjectsHTML += '<div class="row col-sm-12"><div class="col-sm-12 col-md-12 d-flex justify-content-center"><div class="dataTables_paginate paging_simple_numbers" id="example2_paginate"><ul class="pagination">';
		personalProjectsHTML += '<li class="paginate_button page-item previous ' + (personalProjectsPage == 0 ? 'disabled' : '') + '" id="example2_previous"><a href="#" aria-controls="example2" data-dt-idx="' + personalProjectsPage + '" tabindex="0" class="page-link">Previous</a></li>';
		
		var info = numPagesToShowInPagination(parseInt(personalProjectsPage) + 1, personalProjectsTotalPages);
		for (const [key, value] of Object.entries(info.pages)) {
			personalProjectsHTML +=	'<li class="paginate_button page-item ' + ((parseInt(key) + 1 == info.activePageIndex) ? 'active' : '') + '"><a href="#" aria-controls="example2" data-dt-idx="' + value + '" tabindex="0" class="page-link">' + value + '</a></li>';
		}

		personalProjectsHTML += '<li class="paginate_button page-item next ' + ((parseInt(personalProjectsPage) + 1 == personalProjectsTotalPages) ? 'disabled' : '') + '" id="example2_next"><a href="#" aria-controls="example2" data-dt-idx="' + parseInt(parseInt(personalProjectsPage) + 2) + '" tabindex="0" class="page-link">Next</a></li></ul></div></div></div>';
	}
	
	$("#body_personal_projects").html(personalProjectsHTML);
	loadBreadcrumbEvents();
	bindPersonalProjectsPagination();
	bindArticles(); // Important after pagination
}

function bindPersonalProjectsPagination(){
	$(".page-link").click(function(){
		event.preventDefault();
		personalProjectsPage = parseInt($(this).attr("data-dt-idx")) - 1;
		personalProjectsEvents();
	});
}
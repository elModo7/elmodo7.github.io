function numPagesToShowInPagination(curPage, totalPages) {
    // Pagination allows max 7 pages ex: [Prev 1, 2, 3, 4, 5, 6, 7 Next]
    const maxPagesToShow = 5;
    let startPage, endPage;

    if (totalPages <= maxPagesToShow) {
        // Less than or equal to maxPagesToShow, show all pages
        startPage = 1;
        endPage = totalPages;
    } else {
        if (curPage <= Math.ceil(maxPagesToShow / 2)) {
            // Near the start
            startPage = 1;
            endPage = maxPagesToShow;
        } else if (curPage + Math.floor(maxPagesToShow / 2) >= totalPages) {
            // Near the end
            startPage = totalPages - maxPagesToShow + 1;
            endPage = totalPages;
        } else {
            // Somewhere in the middle
            startPage = curPage - Math.floor(maxPagesToShow / 2);
            endPage = curPage + Math.floor(maxPagesToShow / 2);
        }
    }

    // Create the pages array
    const pages = Array.from({
        length: (endPage - startPage + 1)
    }, (_, i) => startPage + i);

    // Determine the active page index within the displayed pages
    let activePageIndex = pages.indexOf(curPage) + 1; // +1 to make it 1-based

    return {
        pages,
        activePageIndex
    };
}

function unbindPagination(){
	$(".page-link").unbind();
}

function loadAboutMeEvent(){
	$(".goAboutMe").unbind();
	$(".goAboutMe").click(function(){
		goAboutMe();
	});
}
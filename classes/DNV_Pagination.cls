/**
 * Created by Martin Satke on 19-Apr-18.
 */
public with sharing class DNV_Pagination {

    public Integer recordTotalCount {get; set;}
    public Integer recordsPerPage {get; set;}
    public Integer currentPage {get; set;}
    public Integer recordLimit {get; set;}

    private static final Integer DEFAULT_RECORDS_PER_PAGE = 10;
    private static Map<String,DNV_Pagination> paginationInstancePerController = new Map<String,DNV_Pagination>();

    public static DNV_Pagination getPaginationInstance(String pageControllerName, Integer recordTotalCount) {
        return getPaginationInstance(pageControllerName, recordTotalCount, null);
    }

    public static DNV_Pagination getPaginationInstance(String pageControllerName, Integer recordTotalCount, Integer recordsPerPage) {
        if (paginationInstancePerController.containsKey(pageControllerName) == false) {
            paginationInstancePerController.put(pageControllerName, new DNV_Pagination(recordTotalCount, recordsPerPage));
        }
        return paginationInstancePerController.get(pageControllerName);
    }

    private DNV_Pagination() {}

    private DNV_Pagination(Integer recordTotalCount) {
        this.recordsPerPage = DEFAULT_RECORDS_PER_PAGE;
        this.currentPage = 1;
        this.recordTotalCount = recordTotalCount;
    }

    private DNV_Pagination(Integer recordTotalCount, Integer recordsPerPage) {
        this.recordsPerPage = (recordsPerPage != null) ? recordsPerPage : DEFAULT_RECORDS_PER_PAGE;
        this.currentPage = 1;
        this.recordTotalCount = recordTotalCount;
    }

    public Integer getOffset() {
        return recordsPerPage * (currentPage - 1);
    }

    public Integer getLimit() {
        return recordsPerPage;
    }

    public Boolean getNextPageAllowed() {
        return (recordTotalCount - (recordsPerPage * currentPage)) > 0;
    }

    public Boolean getPreviousPageAllowed() {
        return ((recordsPerPage * currentPage) - recordsPerPage) > 0;
    }

    public PageReference goToNextPage() {
        if (getNextPageAllowed()) {
            currentPage++;
        }
        return null;
    }

    public PageReference goToPreviousPage() {
        if (getPreviousPageAllowed()) {
            currentPage--;
        }
        return null;
    }
}
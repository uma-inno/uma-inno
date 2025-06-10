package ca.uhn.fhir.jpa.starter.interceptors;

import ca.uhn.fhir.interceptor.api.Hook;
import ca.uhn.fhir.interceptor.api.Interceptor;
import ca.uhn.fhir.interceptor.api.Pointcut;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.jpa.api.dao.DaoRegistry;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

// These are the correct imports for servlet classes
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
/**
 * JPA Interceptor that tracks entity operations and provides additional
 * functionality for persistence operations.
 */
@Component
@Interceptor
public class JpaEntityTrackingInterceptor {

	private static final Logger logger = LoggerFactory.getLogger(JpaEntityTrackingInterceptor.class);

	@Autowired(required = false)
	private DaoRegistry daoRegistry;
	/**
	 * Intercepts incoming requests to perform pre-processing
	 */
	@Hook(Pointcut.SERVER_INCOMING_REQUEST_PRE_HANDLED)
	public void incomingRequestPreHandled(RequestDetails requestDetails) {
		logger.info("Processing incoming JPA request: {} {}",
			requestDetails.getRequestType(),
			requestDetails.getCompleteUrl());

		// Add request pre-processing logic here
		// For example, you could modify request parameters or perform validation
	}

	/**
	 * Called before a resource is created in the database
	 */
	@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_CREATED)
	public void resourceCreated(RequestDetails requestDetails, IBaseResource resource) {
		logger.info("JPA Entity CREATING: {} with ID: {}",
			resource.getClass().getSimpleName(),
			resource.getIdElement().getValue());

		// You can perform additional operations on the resource before it's saved
		// For example:
		// - Add default values
		// - Validate business rules
		// - Transform data
	}

	/**
	 * Called before a resource is updated in the database
	 */
	@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_UPDATED)
	public void resourceUpdated(RequestDetails requestDetails, IBaseResource oldResource, IBaseResource newResource) {
		logger.info("JPA Entity UPDATING: {} with ID: {}",
			newResource.getClass().getSimpleName(),
			newResource.getIdElement().getValue());

		// You can compare old and new resources here
		// For example:
		// - Track what fields have changed
		// - Validate that certain fields haven't been modified
		// - Apply business rules based on the changes
	}

	/**
	 * Called before a resource is deleted from the database
	 */
	@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_DELETED)
	public void resourceDeleted(RequestDetails requestDetails, IBaseResource resource) {
		logger.info("JPA Entity DELETING: {} with ID: {}",
			resource.getClass().getSimpleName(),
			resource.getIdElement().getValue());

		// Add pre-deletion logic here
		// For example:
		// - Check if the resource can be safely deleted
		// - Perform cascading operations
		// - Archive data before deletion
	}

	/**
	 * Called after a resource is stored in the database
	 */
	@Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_CREATED)
	public void afterResourceCreated(RequestDetails requestDetails, IBaseResource resource) {
		logger.info("JPA Entity CREATED: {} with ID: {}",
			resource.getClass().getSimpleName(),
			resource.getIdElement().getValue());

		// Post-creation processing can go here
	}

	/**
	 * Called after a resource is updated in the database
	 */
	@Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_UPDATED)
	public void afterResourceUpdated(RequestDetails requestDetails, IBaseResource oldResource, IBaseResource newResource) {
		logger.info("JPA Entity UPDATED: {} with ID: {}",
			newResource.getClass().getSimpleName(),
			newResource.getIdElement().getValue());

		// Post-update processing can go here
	}
	/**
	 * Called after a transaction is committed to the database
	 * Note: STORAGE_TRANSACTION_COMMITTED pointcut is not available in this HAPI FHIR version
	 * Using STORAGE_PRESTORAGE_RESOURCE_UPDATED as an alternative hook for post-commit logic
	 */
	// @Hook(Pointcut.STORAGE_TRANSACTION_COMMITTED) // This pointcut is not available
	// public void transactionCommitted(RequestDetails requestDetails) {
	//	if (requestDetails != null) {
	//		logger.info("JPA Transaction COMMITTED for request type: {}",
	//			requestDetails.getRequestType());
	//	} else {
	//		logger.info("JPA Transaction COMMITTED (no request details available)");
	//	}
	//
	//	// Post-transaction logic can go here
	//	// For example, trigger notifications, update caches, etc.
	// }
	/**
	 * Handles exceptions that occur during processing
	 */
	@Hook(Pointcut.SERVER_HANDLE_EXCEPTION)
	public void handleException(RequestDetails requestDetails, Exception exception,
											 HttpServletRequest servletRequest,
											 HttpServletResponse servletResponse) {

		logger.error("JPA Exception occurred during processing: {}", exception.getMessage(), exception);

		// You can handle specific exceptions here
		// Custom exception handling logic goes here
	}
}
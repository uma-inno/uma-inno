package ca.uhn.fhir.jpa.starter.interceptors;

import ca.uhn.fhir.interceptor.api.Hook;
import ca.uhn.fhir.interceptor.api.Interceptor;
import ca.uhn.fhir.interceptor.api.Pointcut;
import ca.uhn.fhir.rest.api.server.RequestDetails;
import ca.uhn.fhir.rest.server.exceptions.BaseServerResponseException;
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
		try {
			if (requestDetails != null) {
				logger.info("Processing incoming JPA request: {} {}",
					requestDetails.getRequestType() != null ? requestDetails.getRequestType() : "UNKNOWN",
					requestDetails.getCompleteUrl() != null ? requestDetails.getCompleteUrl() : "UNKNOWN");
			} else {
				logger.warn("Processing incoming JPA request with null RequestDetails");
			}
		} catch (Exception e) {
			logger.error("Error in incomingRequestPreHandled", e);
		}
	}

	/**
	 * Called before a resource is created in the database
	 */
	@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_CREATED)
	public void resourceCreated(RequestDetails requestDetails, IBaseResource resource) {
		try {
			if (resource != null) {
				logger.info("JPA Entity CREATING: {} with ID: {}",
					resource.getClass().getSimpleName(),
					resource.getIdElement() != null ? resource.getIdElement().getValue() : "NO_ID");
			} else {
				logger.warn("Resource creation called with null resource");
			}
		} catch (Exception e) {
			logger.error("Error in resourceCreated hook", e);
		}
	}

	/**
	 * Called before a resource is updated in the database
	 */
	@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_UPDATED)
	public void resourceUpdated(RequestDetails requestDetails, IBaseResource oldResource, IBaseResource newResource) {
		try {
			if (newResource != null) {
				logger.info("JPA Entity UPDATING: {} with ID: {}",
					newResource.getClass().getSimpleName(),
					newResource.getIdElement() != null ? newResource.getIdElement().getValue() : "NO_ID");
			} else {
				logger.warn("Resource update called with null new resource");
			}
		} catch (Exception e) {
			logger.error("Error in resourceUpdated hook", e);
		}
	}

	/**
	 * Called before a resource is deleted from the database
	 */
	@Hook(Pointcut.STORAGE_PRECOMMIT_RESOURCE_DELETED)
	public void resourceDeleted(RequestDetails requestDetails, IBaseResource resource) {
		try {
			if (resource != null) {
				logger.info("JPA Entity DELETING: {} with ID: {}",
					resource.getClass().getSimpleName(),
					resource.getIdElement() != null ? resource.getIdElement().getValue() : "NO_ID");
			} else {
				logger.warn("Resource deletion called with null resource");
			}
		} catch (Exception e) {
			logger.error("Error in resourceDeleted hook", e);
		}
	}

	/**
	 * Called after a resource is stored in the database
	 */
	@Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_CREATED)
	public void afterResourceCreated(RequestDetails requestDetails, IBaseResource resource) {
		try {
			if (resource != null) {
				logger.info("JPA Entity CREATED: {} with ID: {}",
					resource.getClass().getSimpleName(),
					resource.getIdElement() != null ? resource.getIdElement().getValue() : "NO_ID");
			}
		} catch (Exception e) {
			logger.error("Error in afterResourceCreated hook", e);
		}
	}

	/**
	 * Called after a resource is updated in the database
	 */
	@Hook(Pointcut.STORAGE_PRESTORAGE_RESOURCE_UPDATED)
	public void afterResourceUpdated(RequestDetails requestDetails, IBaseResource oldResource, IBaseResource newResource) {
		try {
			if (newResource != null) {
				logger.info("JPA Entity UPDATED: {} with ID: {}",
					newResource.getClass().getSimpleName(),
					newResource.getIdElement() != null ? newResource.getIdElement().getValue() : "NO_ID");
			}
		} catch (Exception e) {
			logger.error("Error in afterResourceUpdated hook", e);
		}
	}

	/**
	 * Handles exceptions that occur during processing
	 * Fixed: The method signature now matches what HAPI FHIR actually calls
	 */
	@Hook(Pointcut.SERVER_HANDLE_EXCEPTION)
	public void handleException(RequestDetails requestDetails, Exception exception) {
		try {
			// Safely extract request information
			String method = "UNKNOWN";
			String url = "UNKNOWN";
			
			if (requestDetails != null) {
				if (requestDetails.getRequestType() != null) {
					method = requestDetails.getRequestType().name();
				}
				if (requestDetails.getCompleteUrl() != null) {
					url = requestDetails.getCompleteUrl();
				}
			}

			// Safely handle the exception
			if (exception != null) {
				String exceptionType = exception.getClass().getSimpleName();
				String message = exception.getMessage() != null ? exception.getMessage() : "No message";
				
				// Log different types of exceptions appropriately
				if (exception instanceof BaseServerResponseException) {
					BaseServerResponseException serverException = (BaseServerResponseException) exception;
					// These are expected FHIR server exceptions (like 401, 403, etc.)
					logger.info("FHIR Server exception during {} {}: {} (Status: {})", 
							  method, url, message, serverException.getStatusCode());
				} else {
					// These are unexpected exceptions that should be investigated
					logger.error("Unexpected exception during {} {}: {} - {}", 
							   method, url, exceptionType, message, exception);
				}
			} else {
				logger.warn("HandleException called with null exception for {} {}", method, url);
			}
		} catch (Exception e) {
			// Prevent any issues in exception handling from causing further problems
			logger.error("Error in exception handler itself", e);
		}
	}
}
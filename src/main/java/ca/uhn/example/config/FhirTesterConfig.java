package ca.uhn.example.config;

import java.io.IOException;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;

import org.springframework.cglib.core.Customizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.beans.factory.annotation.Value;

import org.keycloak.adapters.authorization.integration.jakarta.ServletPolicyEnforcerFilter;
import org.keycloak.adapters.authorization.spi.ConfigurationResolver;
import org.keycloak.adapters.authorization.spi.HttpRequest;
import org.keycloak.representations.adapters.config.PolicyEnforcerConfig;
import org.keycloak.util.SystemPropertiesJsonParserFactory;

import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.resource.web.authentication.BearerTokenAuthenticationFilter;
import org.springframework.security.web.SecurityFilterChain;
import static org.springframework.security.config.Customizer.withDefaults;

import ca.uhn.fhir.context.FhirVersionEnum;
import ca.uhn.fhir.to.FhirTesterMvcConfig;
import ca.uhn.fhir.to.TesterConfig;

//@formatter:off
/**
 * This spring config file configures the web testing module. It serves two
 * purposes:
 * 1. It imports FhirTesterMvcConfig, which is the spring config for the
 *    tester itself
 * 2. It tells the tester which server(s) to talk to, via the testerConfig()
 *    method below
 */
@Configuration
@Import({ FhirTesterMvcConfig.class, Customizer.class })
@EnableWebSecurity
public class FhirTesterConfig {



	@Value("${spring.security.oauth2.resourceserver.jwt.jwk-set-uri}")
	String jwkSetUri;

	@Bean
	public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
		http
				.authorizeHttpRequests((authorize) -> authorize
						.anyRequest().authenticated()
				)
				.oauth2ResourceServer((oauth2) -> oauth2
						.jwt(withDefaults())
				)
				.addFilterAfter(createPolicyEnforcerFilter(), BearerTokenAuthenticationFilter.class);
		return http.build();
	}

	private ServletPolicyEnforcerFilter createPolicyEnforcerFilter() {
		PolicyEnforcerConfig config;

		try {
			ObjectMapper mapper = new ObjectMapper(new SystemPropertiesJsonParserFactory());
			mapper.setSerializationInclusion(JsonInclude.Include.NON_DEFAULT);
			config = mapper.readValue(getClass().getResourceAsStream("/policy-enforcer.json"), PolicyEnforcerConfig.class);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		return new ServletPolicyEnforcerFilter(new ConfigurationResolver() {
			@Override
			public PolicyEnforcerConfig resolve(HttpRequest request) {
				return config;
			}
		});
	}

	@Bean
	JwtDecoder jwtDecoder() {
		return NimbusJwtDecoder.withJwkSetUri(this.jwkSetUri).build();
	}

	/**
	 * This bean tells the testing webpage which servers it should configure itself
	 * to communicate with. In this example we configure it to talk to the local
	 * server, as well as one public server. If you are creating a project to
	 * deploy somewhere else, you might choose to only put your own server's
	 * address here.
	 */

	@Bean
	public TesterConfig testerConfig() {
		TesterConfig retVal = new TesterConfig();
		retVal
			.addServer()
				.withId("home")
				.withFhirVersion(FhirVersionEnum.R5)
				.withBaseUrl("http://localhost:8080/fhir/")
				.withName("Local Tester");

		/*
		 * Use the method below to supply a client "factory" which can be used 
		 * if your server requires authentication
		 */
		// retVal.setClientFactory(clientFactory);
		
		return retVal;
	}
	
}
//@formatter:on

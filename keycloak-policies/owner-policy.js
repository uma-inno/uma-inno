// Owner Policy - Grants access to resource owners
var context = $evaluation.getContext();
var identity = context.getIdentity();
var permission = $evaluation.getPermission();
var resource = permission.getResource();

if (resource) {
    var owner = resource.getOwner();
    var userId = identity.getId();
    
    // Use .equals() for Java string comparison
    if (owner != null && owner.equals(userId)) {
        $evaluation.grant();
    }
}

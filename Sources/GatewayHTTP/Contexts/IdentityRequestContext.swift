package import HarborAuthentication
package import Hummingbird
package import HummingbirdAuth

/// The caller tier's context: reaching a handler through it, behind `IsAuthenticatedMiddleware`, means
/// `identity` is set.
package struct IdentityRequestContext: ChildRequestContext, AuthRequestContext {
    package var coreContext: CoreRequestContextStorage
    package var identity: UserIdentity?

    /// Carries the parent's storage rather than rebuilding it: path parameters are already extracted by the
    /// time a child context is made.
    package init(context: BasicRequestContext) throws {
        self.coreContext = context.coreContext
        self.identity = nil
    }
}

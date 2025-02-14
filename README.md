# bohurupi_order_flutter

A new Flutter project.
Below is a detailed explanation of each page in the Bohurupi Order Flutter project along with their workflow steps:
---
DashboardPage Workflow
Purpose:
Presents an overview of order statistics and recent activities for quick insights.
Workflow:
Initialization:
As a ConsumerStatefulWidget, on initState the page calls the dashboard provider’s loadDashboardData() (via a microtask) to fetch summary data.
Data Loading:
Uses ref.watch(dashboardProvider) within build() to obtain the current dashboard state.
While fetching data, displays a loading indicator if the state is loading and no stats are available.
3. Error Handling:
If an error occurs, an error view is rendered with a message and a retry option.
Display:
Once data is fetched successfully, the page displays summary cards/components showing order counts, recent activities, and key stats.
5. Navigation:
A floating navigation bar (via FloatingNavBar) is available, allowing quick navigation to other parts of the app.
---
CreateOrderPage Workflow
Purpose:
Allows the user to create or edit an order using a combined form view and table view.
Workflow:
1. Initialization:
Implemented as a ConsumerStatefulWidget with an internal toggle (_isTableView) to switch between form and table views.
In initState, a post-frame callback invalidates the apiOrdersProvider to load fresh order data.
2. Order Form:
Displays the OrderForm component where the user can enter or modify order details (including products list).
Uses hooks (e.g., memoized controllers, form key) to manage field state and cleanup.
Submission Handling:
On form submission, the method _handleOrderSubmit determines whether the order should be created or updated.
Calls the corresponding mutation method (either create or update) via the provider’s mutation instance.
Refreshing Data:
After submission completes, the orders provider is invalidated to trigger a refresh of the order list.
A refresh indicator (_handleRefresh) is available to manually trigger data reloading.
5. View Toggling:
The page allows toggling between a table view (using OrderTable) and a form view to suit different workflows.
---
FirebasePendingPage Workflow
Purpose:
Displays a list of pending orders fetched from the Firebase backend with search and pagination capabilities.
Workflow:
Cache Validation:
Uses a cache time provider (pendingOrdersCacheTimeProvider) and a defined cache duration to decide if new data needs to be fetched.
A helper function (isCacheValid()) checks if the time elapsed since the last fetch exceeds the cache duration.
Data Fetching:
In the useEffect hook, if no orders exist or the cache is invalid, a microtask calls fetchOrders() from the pending orders notifier.
The cache timestamp is updated right after fetching.
3. Memoization & Transformation:
The list of raw JSON orders is memoized and mapped to FirebaseOrder objects using useMemoized(). This prevents unnecessary rebuilds.
User Actions:
Searching: A callback (onSearch) triggers a fresh fetch (if needed) and sets the search query.
Pagination: A callback (onPageChanged) handles page changes (and re-fetch if the cache is invalid).
Display:
The page renders the orders using an OrdersPageLayout component which takes care of showing loading indicators, errors, and the actual list of orders.
---
FirebaseCompletedPage Workflow
Purpose:
Lists completed orders from Firebase with similar search, pagination, and cache-handling as the pending orders page.
Workflow:
Cache Validation:
Utilizes its own cache provider (completedOrdersCacheTimeProvider) and a set cache duration to determine if a new data fetch is required.
2. Data Fetching:
The useEffect hook determines if the orders list is empty or if the cache has expired.
If needed, it triggers the fetchOrders() method from the completed orders notifier and updates the cache timestamp.
3. Data Transformation:
Order data is converted to FirebaseOrder objects using useMemoized(), ensuring optimal UI updates.
4. User Interactions:
Search: An onSearch callback allows the user to update the search query, possibly triggering a refetch.
Pagination: An onPageChanged callback facilitates moving between pages.
5. Rendering:
Orders are displayed within an OrdersPageLayout, with built-in error handling, manual refresh support, and dynamic page updates.
---
WooOrdersPage Workflow
Purpose:
Displays WooCommerce orders with built-in search, filtering, pagination, and manual refresh functionalities.
Workflow:
Initialization & Caching:
Uses a dedicated cache time provider (wooOrdersCacheTimeProvider) to manage data freshness.
At startup, checks cache validity; if invalid or data is missing, triggers a fetch via the Woo orders notifier.
Data Fetching:
Orders are fetched from the WooCommerce API using a service that builds HTTP GET requests with query parameters such as page, search terms, and status.
The provider listens for changes and updates UI accordingly.
User Interactions:
Search Field: An input field calls an onSearch callback that sets the search query and checks cache status.
Refresh: A refresh button (icon) calls the onRefresh method to invalidate and re-fetch the data.
Pagination: The onPageChanged callback updates the current page and triggers data reloading if needed.
Display:
Uses OrdersPageLayout to display the orders list.
The layout includes a custom search bar, pagination controls, and a refresh icon, ensuring a responsive UI.
Error Handling:
In case of API or network errors, the page provides an error view with guidance on retrying.
---
Each page in the Bohurupi Order Flutter project leverages Riverpod for state management, uses hooks for efficient widget lifecycles, and calls the appropriate services to ensure data is fetched, cached, and updated. This organized workflow not only provides a seamless user experience but also keeps the codebase maintainable and scalable.

Below is an overall summary of the Bohurupi Order Flutter app’s workflow, its components, and pages. This high-level guide is intended to help someone understand the app’s design so they can recreate a similar system.
---
Total App Workflow Overview
Architecture & Core Concepts
Clean Architecture: The app is divided into UI (pages and components), state management (using Riverpod and Flutter Hooks), and services (for API interaction and authentication).
State Management: Riverpod providers manage state for orders, caching, and tracking data. Flutter Hooks are used for lifecycle management and memoization to optimize rebuilds.
Dependency Injection & Environment: A central EnvironmentService manages API URLs, headers, and authentication tokens for all API calls.
Pages & Their Roles
DashboardPage:
Purpose: Displays an overview of order statistics and recent activity.
Workflow:
On initialization, it triggers the dashboard provider to fetch summary data.
Shows loading indicators, handles errors, and presents key statistics via summary cards.
Uses a floating navigation bar for quick access to other sections.
CreateOrderPage:
Purpose: Allows users to create or edit an order.
Workflow:
Toggles between a form view (OrderForm) and a table view (OrderTable) for listing orders.
Utilizes hooks to manage form state and post-frame callbacks to refresh data.
On submission, calls mutation methods to either create or update orders, then refreshes the order list.
FirebasePendingPage:
Purpose: Displays a list of pending orders from the Firebase backend.
Workflow:
Validates cache using a cache time provider before fetching data.
Uses hooks to fetch, memoize, and transform raw JSON orders into FirebaseOrder objects.
Implements search and pagination callbacks to refresh data when required.
FirebaseCompletedPage:
Purpose: Lists completed orders fetched from Firebase, using similar strategies as the pending page.
Workflow:
Checks for data freshness via caching, fetches new data if needed.
Allows searching and pagination; converts raw data into order models and updates the UI accordingly.
WooOrdersPage:
Purpose: Displays orders from WooCommerce with filtering, search, and refresh functionalities.
Workflow:
On initialization, checks cache validity; if invalid, fetches data using a WooCommerce service.
Provides input for search and pagination controls to manage and display orders dynamically.
Uses error handling to display retry options on API failures.
Core Components
OrderForm & ProductCard:
Handles order input with Flutter Hooks to manage controllers, keys, and cleanup.
ProductCard is used within the form to display individual product details.
OrderTable & OrderCard:
OrderTable displays orders in a tabular format with pagination controls and actions (e.g., delete).
OrderCard offers a card-style view with summary information for each order.
Order Details & Tracking:
FirebaseOrderDetailsDialog / WooOrderDetailsDialog:
Modal dialogs that display detailed information about an order, with options for actions such as deletion.
OrderTrackingDialog:
Displays tracking information for an order by calling the TrackingService; handles loading states and error views.
FloatingNavBar:
A persistent navigation component that allows users to quickly switch between major sections of the app.
OrdersPageLayout:
A reusable layout component used across pages (Firebase Pending/Completed, WooOrders) that provides standard UI for listing orders, displaying search bars, pagination controls, and refresh buttons.
Services & API Interactions
ApiOrdersService, FirebaseOrdersService, WooOrdersService:
These services build and execute HTTP requests to fetch, update, or delete order data from respective endpoints.
They handle query parameter construction (e.g., pagination, search terms) and error management (e.g., auth errors, network failures).
TrackingService:
Retrieves shipment tracking information via HTTP GET requests, using a tracking ID as a parameter.
Implements error handling with different status codes (e.g., 404 for not found, 401/403 for unauthorized).
EnvironmentService:
Centralizes configuration including base URLs, headers, and authentication tokens.
Manages token generation and expiration, ensuring that all API calls include required authentication details.
---
How It All Works Together
Entry Point:
The user lands on the DashboardPage, which provides an at-a-glance overview of order statistics and recent activity.
Order Management:
Navigating to the CreateOrderPage allows users to either create or edit orders. They can toggle between filling in an order form and viewing the list of existing orders. On submission, the respective API service is called to update the backend.
Order Listing & Detailed Views:
FirebasePendingPage and FirebaseCompletedPage fetch and display the respective orders from Firebase. Caching and hooks ensure that if the orders list is up-to-date, redundant API calls are avoided.
WooOrdersPage performs a similar function for WooCommerce orders, with additional filtering and search capabilities.
Component Interaction:
Selecting an individual order opens a details dialog (either for Firebase or WooCommerce orders) while a tracking dialog can be invoked to check shipment progress. The dialogs call their respective services to fetch detailed data for display.
Navigation & Refresh:
A floating navigation bar is accessible across pages for quick transitions. Each page supports manual refresh along with automated cache invalidation to ensure the data remains current.
---
By following the described workflows, components, and structure, one can recreate the Bohurupi Order Flutter app. The clear separation of UI, state management, and services—along with the use of design patterns like caching, hooks for lifecycle management, and a central environment configuration—ensures maintainability, scalability, and a clean codebase.
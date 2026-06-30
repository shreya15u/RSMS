 🛍️ Luxury Retail Store Management System (RSMS)                                                                    
                                                                                                                     
  A premium, role-based iOS/iPadOS application designed exclusively for luxury retail operations. This app bridges   
  the                                                                                                                
  gap between front-of-house clienteling and back-of-house inventory fulfillment, providing a seamless digital       
  ecosystem                                                                                                          
  for every tier of retail staff.                                                                                    
                                                                                                                     
  ## 📱 What is this app?                                                                                            
                                                                                                                     
  The RSMS (Retail Store Management System) is an all-in-one boutique management platform. It allows luxury brands to
  handle high-touch VIP clienteling, process Point of Sale (POS) checkouts, audit physical inventory by unique serial
  numbers, dispatch Ship-From-Store (SFS) orders, and analyze global or boutique-level analytics—all synced in real- 
  time.                                                                                                              
                                                                                                                     
  ## 👥 User Roles & Capabilities                                                                                    
                                                                                                                     
  The application architecture is strictly role-driven, ensuring users only see the tools they need:                 
                                                                                                                     
  1. 👔 Corporate Admin                                                                                              
      • Oversees multi-boutique operations globally.                                                                 
      • Manages global product Catalogs (Blueprints) and tracks overall sales performance.                           
      • Monitors live system logs and high-level revenue analytics.                                                  
  2. 🏬 Boutique Manager (BM)                                                                                        
      • Manages single-store operations and local staff configurations.                                              
      • Authorizes high-discount POS approvals.                                                                      
      • Views store-specific sales targets and team performance.                                                     
  3. 💼 Sales Associate (SA)                                                                                         
      • Clienteling: Manages VIP profiles, wishlists, and purchase histories.                                        
      • POS Checkout: Rings up items, scans barcodes, and processes transactions (which instantly reserves stock).   
      • Appointments: Books and manages client visits.                                                               
  4. 📦 Inventory Controller (IC)                                                                                    
      • Manages the physical vault/stock room.                                                                       
      • SFS Fulfillment: Receives "Pending" orders triggered by the SA's POS, secures physical serial numbers, and   
      dispatches them to complete the handover.                                                                      
      • Stock Auditing: Tracks items down to the individual serial number state ( Available ,  Reserved ,  Sold ).   
                                                                                                                     
                                                                                                                     
  ## 🛠️ Tech Stack                                                                                                    
                                                                                                                     
  • Platform: Native iOS / iPadOS                                                                                    
  • UI Framework: SwiftUI                                                                                            
  • Language: Swift 5.9+                                                                                             
  • Concurrency: Modern Swift Concurrency ( async/await ,  Task ,  MainActor )                                       
  • State Management: Observation Framework ( @Observable )                                                          
  • Backend: Supabase                                                                                                
      • Database: PostgreSQL (with Row Level Security)                                                               
      • API: PostgREST client via  supabase-swift                                                                    
      • Auth: Supabase Auth (JWT role-based mapping)                                                                 
      • Storage: Supabase Storage (for catalog images and client media)                                              
                                                                                                                     
                                                                                                                     
  ## 📂 Folder Structure                                                                                             
                                                                                                                     
  The codebase follows a modular, feature-based architecture heavily segmented by user roles:                        
                                                                                                                     
    luxury/                                                                                                          
    ├── App/                 # App entry point, lifecycle, and global Router                                         
    ├── Assets.xcassets/     # App icons, images, and custom color sets                                              
    ├── Common/              # Reusable UI components (CustomButtons, standard modifiers) and Theme Managers (Fonts, 
  Colors)                                                                                                            
    ├── Config/              # Global Entity definitions mapping directly to Supabase schemas (e.g., CatalogEntity,  
  InventoryUnitEntity)                                                                                               
    ├── Core/                # The heart of the app, segmented by role:                                              
    │   ├── Auth/                 # Login, session management                                                        
    │   ├── BoutiqueManager/      # BM specific views and ViewModels                                                 
    │   ├── CorporateAdmin/       # Global dashboards, Catalog CRUD, system logs                                     
    │   ├── InventoryController/  # Physical stock lists, backroom auditing                                          
    │   ├── SalesAssociate/       # Clienteling, Client Profile, POS, Cart                                           
    │   └── Shared/               # Services used across all roles (InventoryService, ProfileService,                
  SupabaseManager)                                                                                                   
    └── Features/            # Cross-functional modules shared by multiple roles                                     
        └── SFS/                  # Ship-From-Store fulfillment, scanning, dispatch logic                            
                                                                                                                     
  ## 🔄 Core Data Flow (The Handover Process)                                                                        
                                                                                                                     
  One of the most complex modules is the SA-to-IC POS handover. The system strictly tracks physical items using dual 
  models ( CatalogEntity  for blueprints,  InventoryUnitEntity  for physical stock):                                 
                                                                                                                     
  1. Sale: SA creates a POS cart. The app finds an  .available  unit in their specific boutique and switches it to  .
  reserved .                                                                                                         
  2. Pending: A  purchased_items  order is generated as  Pending .                                                   
  3. Securing: The IC sees the  Pending  ticket, physically retrieves the item from the vault, and updates the status.
  4. Dispatching: The IC hands the product to the SA or ships it. Hitting "Dispatch" converts the physical item to  .
  sold  and the order to  Completed , updating Global Sales Analytics instantly.                                     
                                                                                                                     
  ## 🚀 Getting Started                                                                                              
                                                                                                                     
  1. Clone the repository.                                                                                           
  2. Open  luxury.xcodeproj  in Xcode 15+.                                                                           
  3. Ensure your  SupabaseManager  is configured with the correct  SUPABASE_URL  and  SUPABASE_ANON_KEY .            
  4. Target an iPad or iPhone simulator and hit Run (⌘ + R).   

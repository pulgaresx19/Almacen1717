const supabaseUrl = 'https://cleqppfzfuljynhxjlst.supabase.co';
const supabaseKey = 'sb_publishable_GxFV2KWcAm9HggC1u-byFg_53EJfJrH';
const supabaseClient = supabase.createClient(supabaseUrl, supabaseKey);

document.addEventListener('DOMContentLoaded', async () => {
    const usersTableBody = document.getElementById('users-table-body');
    const flightsTableBody = document.getElementById('flights-table-body');
    const totalUsersCounter = document.getElementById('total-users-counter');
    const sidebarName = document.getElementById('sidebar-name');
    const sidebarAvatar = document.getElementById('sidebar-avatar');
    
    const registerForm = document.getElementById('register-form');
    const loginForm = document.getElementById('login-form');
    const logoutBtn = document.getElementById('logout-btn');

    // ------- PROTECCIÓN DE RUTAS -------
    // SPA Sidebar Navigation Logic
    const navItems = document.querySelectorAll('.nav-item');
    const viewSections = document.querySelectorAll('.view-section');

    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault(); // Evitamos que el href recargue o mueva la página
            
            // 1. Quitar 'active' a todos los links y ponerlo al presionado
            navItems.forEach(nav => nav.classList.remove('active'));
            item.classList.add('active');

            // 2. Obtener el ID de la sección objetivo
            const targetId = item.getAttribute('data-target');

            // 3. Ocultar todas las secciones y mostrar la objetivo con transición
            viewSections.forEach(section => {
                if(section.id === targetId) {
                    section.classList.remove('hidden-section');
                    section.classList.add('active-section');
                    
                    // Pequeña animación de entrada (opcional, ajustando opacidad)
                    section.style.opacity = '0';
                    setTimeout(() => section.style.opacity = '1', 50);

                    // Auto load logic
                    if (targetId === 'delivers-section' && typeof window.loadDeliveries === 'function') {
                        window.loadDeliveries();
                    }
                    if (targetId === 'flights-section' || targetId === 'flight-section') {
                        if (typeof window.fetchFlights === 'function') window.fetchFlights();
                    }
                    if (targetId === 'uld-section' && typeof window.fetchGlobalUlds === 'function') {
                        window.fetchGlobalUlds();
                    }
                    if (targetId === 'awb-section' && typeof window.fetchGlobalAwbs === 'function') {
                        window.fetchGlobalAwbs();
                    }
                    if (targetId === 'users-section' && typeof window.loadUsers === 'function') {
                        window.loadUsers();
                    }
                } else {
                    section.classList.add('hidden-section');
                    section.classList.remove('active-section');
                    section.style.opacity = '0';
                }
            });
        });
    });

    // Lógica para botones internos (Add Flight y Cancel)
    const addFlightBtn = document.getElementById('add-flight-btn');
    const cancelAddFlightBtn = document.getElementById('cancel-add-flight-btn');
    const backToFlightsBtn = document.getElementById('back-to-flights-btn');

    function showFlightForm() {
        viewSections.forEach(section => {
            if(section.id === 'add-flight-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    function hideFlightForm() {
        viewSections.forEach(section => {
            if(section.id === 'flight-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    if(addFlightBtn) addFlightBtn.addEventListener('click', showFlightForm);
    if(cancelAddFlightBtn) cancelAddFlightBtn.addEventListener('click', hideFlightForm);
    if(backToFlightsBtn) backToFlightsBtn.addEventListener('click', hideFlightForm);

    window.showAddUserForm = function() {
        viewSections.forEach(section => {
            if(section.id === 'add-user-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    window.hideAddUserForm = function() {
        viewSections.forEach(section => {
            if(section.id === 'users-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
                if (typeof window.loadUsers === 'function') {
                    window.loadUsers();
                }
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    window.loadUsers = async function(searchQuery = '') {
        const tableBody = document.getElementById('users-table-body');
        if (!tableBody) return;

        tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #94a3b8; font-style: italic; padding: 32px;">Loading users...</td></tr>';

        try {
            console.log("Attempting to fetch from 'Users' table...");
            
            // Simple select, no search filters yet to isolate the issue
            const { data, error } = await supabaseClient.from('Users').select('*');
            
            console.log("Supabase raw response - Data:", data);
            console.log("Supabase raw response - Error:", error);

            if (error) {
                alert("Database Error fetching Users: " + error.message + " (Code: " + error.code + ")");
                throw error;
            }

            if (!data || data.length === 0) {
                tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #94a3b8; font-style: italic; padding: 32px;">No users found. (Table might be empty or RLS still active)</td></tr>';
                return;
            }

            tableBody.innerHTML = '';
            data.forEach(user => {
                const tr = document.createElement('tr');
                
                const initial = (user['full-name'] || 'U').charAt(0).toUpperCase();

                tr.innerHTML = `
                    <td>
                        <div class="member-cell">
                            <div class="td-avatar" style="background: #e0e7ff; color: #4338ca;">
                                ${initial}
                            </div>
                            <span>${user['full-name'] || 'Unknown'}</span>
                        </div>
                    </td>
                    <td>${user.email || '-'}</td>
                    <td>
                        <span style="background: #e2e8f0; color: #475569; padding: 4px 10px; border-radius: 6px; font-size: 12px; font-weight: 600;">
                            ${user.position || '-'}
                        </span>
                    </td>
                    <td>${user.building || '-'}</td>
                    <td style="text-align: center;">
                        <span style="background: #f8fafc; border: 1px solid #cbd5e1; padding: 4px 8px; border-radius: 6px; font-weight: 600;">
                            ${user.shift || '-'}
                        </span>
                    </td>
                    <td style="text-align: right;">
                        <span style="background: #f1f5f9; border: 1px solid #e2e8f0; color: #475569; padding: 6px 12px; border-radius: 8px; font-size: 13px; font-weight: 600; font-family: monospace;">
                            ${user['phone-number'] || '-'}
                        </span>
                    </td>
                `;
                tableBody.appendChild(tr);
            });
        } catch (err) {
            console.error("Error loading users:", err);
            tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: #ef4444; padding: 32px;">Failed to load users.</td></tr>';
        }
    };

    const usersSearchInput = document.getElementById('users-search-input');
    if (usersSearchInput) {
        usersSearchInput.addEventListener('input', (e) => {
            if (typeof window.loadUsers === 'function') {
                window.loadUsers(e.target.value.trim());
            }
        });
    }

    // Add User Logic
    const addUserSaveBtn = document.getElementById('add-user-save-btn');
    if (addUserSaveBtn) {
        addUserSaveBtn.addEventListener('click', async () => {
            const fullName = document.getElementById('user-add-fullname').value.trim();
            const email = document.getElementById('user-add-email').value.trim();
            const password = document.getElementById('user-add-password').value;
            const phone = document.getElementById('user-add-phone').value.trim();
            const position = document.getElementById('user-add-position').value.trim();
            const building = document.getElementById('user-add-building').value.trim();
            const shift = document.getElementById('user-add-custom').value; // dropdown for Shift

            if (!fullName || !email || !password) {
                alert('Please fill in all required fields (Full Name, Email, Password).');
                return;
            }

            addUserSaveBtn.disabled = true;
            addUserSaveBtn.textContent = 'Saving...';

            try {
                // 1. Create User in Supabase Auth
                const { data: authData, error: authError } = await supabaseClient.auth.signUp({
                    email: email,
                    password: password,
                    options: { data: { name: fullName } }
                });

                if (authError) throw authError;

                const userId = authData.user?.id;
                if (!userId) throw new Error("Could not retrieve Auth User ID");

                // 2. Insert User into the "Users" table with U uppercase
                const { error: dbError } = await supabaseClient.from('Users').insert([{
                    'ref-ID': userId,
                    'full-name': fullName,
                    'email': email,
                    'phone-number': phone,
                    'position': position,
                    'building': building,
                    'shift': shift
                }]);

                if (dbError) throw dbError;

                alert('User created successfully!');
                
                // Clear the form
                document.getElementById('user-add-fullname').value = '';
                document.getElementById('user-add-email').value = '';
                document.getElementById('user-add-password').value = '';
                document.getElementById('user-add-phone').value = '';
                document.getElementById('user-add-position').value = '';
                document.getElementById('user-add-building').value = '';
                document.getElementById('user-add-custom').value = '1';

                window.hideAddUserForm();
            } catch (err) {
                console.error("Error creating user:", err);
                alert('Error processing request: ' + err.message);
            } finally {
                addUserSaveBtn.disabled = false;
                addUserSaveBtn.textContent = 'Create User';
            }
        });
    }

    // Lógica para botones internos ULD (Add ULD y Cancel)
    const showAddUldBtn = document.getElementById('show-add-uld-btn');
    const cancelAddUldBtn = document.getElementById('cancel-add-uld-btn');
    const backToUldsBtn = document.getElementById('back-to-ulds-btn');

    function showUldForm() {
        viewSections.forEach(section => {
            if(section.id === 'add-uld-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    function hideUldForm() {
        viewSections.forEach(section => {
            if(section.id === 'uld-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    if(showAddUldBtn) showAddUldBtn.addEventListener('click', showUldForm);
    if(cancelAddUldBtn) cancelAddUldBtn.addEventListener('click', hideUldForm);
    if(backToUldsBtn) backToUldsBtn.addEventListener('click', hideUldForm);

    // Lógica para botones internos AWB (Add AWB y Cancel)
    const showAddAwbBtn = document.getElementById('show-add-awb-btn');
    const cancelAddAwbBtn = document.getElementById('cancel-add-awb-btn');
    const backToAwbsBtn = document.getElementById('back-to-awbs-btn');

    function showAwbForm() {
        if(typeof window.populateFlightDropdownForAwb === 'function') window.populateFlightDropdownForAwb();
        viewSections.forEach(section => {
            if(section.id === 'add-awb-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    function hideAwbForm() {
        viewSections.forEach(section => {
            if(section.id === 'awb-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    if(showAddAwbBtn) showAddAwbBtn.addEventListener('click', showAwbForm);
    if(cancelAddAwbBtn) cancelAddAwbBtn.addEventListener('click', hideAwbForm);
    if(backToAwbsBtn) backToAwbsBtn.addEventListener('click', hideAwbForm);

    // Lógica para Deliveries
    const addDeliverBtn = document.getElementById('add-deliver-btn');
    const backToDeliversBtn = document.getElementById('back-to-delivers-btn');

    function showDeliverForm() {
        viewSections.forEach(section => {
            if(section.id === 'add-deliver-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
                if (typeof window.loadReadyAwbsForDelivery === 'function') {
                    window.loadReadyAwbsForDelivery(); // load the table when showing form
                }
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    function hideDeliverForm() {
        viewSections.forEach(section => {
            if(section.id === 'delivers-section') {
                section.classList.remove('hidden-section');
                section.classList.add('active-section');
                section.style.opacity = '0';
                setTimeout(() => section.style.opacity = '1', 50);
                if (typeof window.loadDeliveries === 'function') {
                    window.loadDeliveries();
                }
            } else {
                section.classList.add('hidden-section');
                section.classList.remove('active-section');
                section.style.opacity = '0';
            }
        });
    }

    if(addDeliverBtn) addDeliverBtn.addEventListener('click', showDeliverForm);
    if(backToDeliversBtn) backToDeliversBtn.addEventListener('click', hideDeliverForm);

    // Revisar si hay un usuario autenticado
    const { data: { session } } = await supabaseClient.auth.getSession();
    
    // Si estamos en la página de listado (index.html, que tiene la tabla) y NO hay sesión, mandar a login
    if (usersTableBody && !session) {
        window.location.href = 'login.html';
        return; // Detener ejecución aquí
    }

    // Si estamos en login o register y SÍ hay sesión, mandar a index
    if ((loginForm || registerForm) && session) {
        window.location.href = 'index.html';
        return;
    }

    // ------- MANEJAR CERRAR SESIÓN -------
    if (logoutBtn) {
        logoutBtn.addEventListener('click', async () => {
            const { error } = await supabaseClient.auth.signOut();
            if (error) {
                console.error("Error al cerrar sesión:", error);
                alert("Hubo un problema al cerrar sesión.");
            } else {
                window.location.href = 'login.html'; 
            }
        });
    }

    // ------- MANEJAR INICIAR SESIÓN (login.html) -------
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const btn = loginForm.querySelector('button[type="submit"]');

            // Estado de carga
            btn.disabled = true;
            btn.textContent = 'Iniciando sesión...';

            const { data, error } = await supabaseClient.auth.signInWithPassword({
                email: email,
                password: password,
            });

            if (error) {
                alert('Usuario o contraseña incorrectos.');
                btn.disabled = false;
                btn.textContent = 'Iniciar Sesión';
            } else {
                window.location.href = 'index.html';
            }
        });
    }

    // ------- DASHBOARD - LISTADO DE USUARIOS (index.html) -------
    if (usersTableBody && session) {
        
        // Colocar detalles del usuario autenticado en la barra lateral
        const userEmail = session.user.email;
        const userName = session.user.user_metadata?.name || 'User';
        const userInitial = userName.charAt(0).toUpperCase() || userEmail.charAt(0).toUpperCase();

        if (sidebarName) sidebarName.textContent = userName !== 'User' ? userName : userEmail;
        if (sidebarAvatar) sidebarAvatar.textContent = userInitial;

        async function fetchUsers() {
            try {
                // Intento de llamar a usuarios de Supabase
                const { data, error, count } = await supabaseClient
                    .from('profiles')
                    .select('*', { count: 'exact' });
                
                if (error) {
                    console.log("Mostrando demo fallback (requiere tabla pública 'profiles').");
                    renderDemoUsers();
                    return;
                }

                if (data && data.length > 0) {
                    renderUsers(data, count || data.length);
                } else {
                    renderDemoUsers(); 
                }

            } catch (err) {
                renderDemoUsers();
            }
        }

        function renderUsers(usersMap, totalCount) {
            usersTableBody.innerHTML = ''; 
            if(totalUsersCounter) totalUsersCounter.textContent = totalCount;

            usersMap.forEach(user => {
                const tr = document.createElement('tr');
                const displayEmail = user.email || 'usuario@correo.com';
                const displayName = user.name || 'Custom Name';
                const initial = displayName.charAt(0).toUpperCase() || displayEmail.charAt(0).toUpperCase();
                // Fecha de creación mockeada o real
                const date = new Date(user.created_at || Date.now()).toLocaleDateString();

                tr.innerHTML = `
                    <td>
                        <div class="member-cell">
                            <div class="td-avatar">${initial}</div>
                            <span>${displayName}</span>
                        </div>
                    </td>
                    <td>${displayEmail}</td>
                    <td>[MEd]</td>
                    <td>[relative]</td>
                    <td class="status-active">Active</td>
                `;
                usersTableBody.appendChild(tr);
            });
        }
        
        function renderDemoUsers() {
            usersTableBody.innerHTML = '';
            
            const demoUsers = [
                { email: userEmail, name: userName, created_at: session.user.created_at || new Date() },
                { email: 'admin@dominio.com', name: 'Sophia Admin', created_at: new Date('2023-01-15') },
                { email: 'user@domainname.com', name: 'Custom Name', created_at: new Date('2023-05-22') },
                { email: 'user@domainname.com', name: 'Custom Name', created_at: new Date('2023-08-11') },
                { email: 'user@domainname.com', name: 'Custom Name', created_at: new Date('2024-02-10') }
            ];
            
            if(totalUsersCounter) totalUsersCounter.textContent = "56.4k"; // Hardcoded from image

            demoUsers.forEach((user, index) => {
                const init = user.name.charAt(0).toUpperCase();
                
                // Usaremos algunas fotos random de avatar para imitar la visual de la imagen,
                // si no hay imagen, mostrará la inicial.
                let avatarHtml = `<div class="td-avatar">${init}</div>`;
                if(index > 0) {
                    // Simulando las fotos del mockup
                    avatarHtml = `<div class="td-avatar"><img src="https://i.pravatar.cc/100?img=${index + 10}" alt="avatar"></div>`;
                }

                usersTableBody.insertAdjacentHTML('beforeend', `
                    <tr>
                        <td>
                            <div class="member-cell">
                                ${avatarHtml}
                                <span>${user.name}</span>
                            </div>
                        </td>
                        <td>${user.email}</td>
                        <td>[MEd]</td>
                        <td>[relative]</td>
                        <td class="status-active">Active</td>
                    </tr>
                `);
            });
        }
        // ---------- INICIO LÓGICA DE VUELOS (Flight) ----------
        if (flightsTableBody) {
            window.fetchFlights = async function() {
                try {
                    // Consultamos la tabla 'Flight' de Supabase (o 'flights', probaremos 'Flight' por tu mensaje)
                    const { data, error } = await supabaseClient.from('Flight').select('*');
                    
                    if (error) {
                        console.log("Error consultando 'Flight'. Intentando 'flights'...", error.message);
                        const fallbackResponse = await supabaseClient.from('flights').select('*');
                        if (fallbackResponse.error) {
                            renderDemoFlights();
                            return;
                        }
                        if (fallbackResponse.data && fallbackResponse.data.length > 0) {
                            renderFlights(fallbackResponse.data);
                        } else {
                            renderDemoFlights();
                        }
                        return;
                    }

                    if (data && data.length > 0) {
                        renderFlights(data);
                    } else {
                        renderDemoFlights();
                    }

                } catch (err) {
                    renderDemoFlights();
                }
            }

            function renderFlights(flightsArray) {
                flightsTableBody.innerHTML = ''; 
                
                // Sort by date descending (most recent first), but time ascending (AM before PM for the same day)
                flightsArray.sort((a, b) => {
                    const dateA = a['date-arrived'] || '1970-01-01';
                    const dateB = b['date-arrived'] || '1970-01-01';
                    
                    // Compare Dates first (Descending)
                    if (dateA !== dateB) {
                        return dateB.localeCompare(dateA); 
                    }
                    
                    // If Dates are exactly the same, compare Times (Ascending)
                    const timeA = a['time-arrived'] || '00:00';
                    const timeB = b['time-arrived'] || '00:00';
                    return timeA.localeCompare(timeB);
                });
                
                flightsArray.forEach((flight, index) => {
                    const tr = document.createElement('tr');
                    const carrier = flight.carrier || '-';
                    const number = flight.number || '-';
                    const breakVal = flight['cant-break'] || '0';
                    const noBreakVal = flight['cant-noBreak'] || '0';
                    const startBreakRaw = flight['start-break'] || '-';
                    const endBreakRaw = flight['end-break'] || '-';
                    const startBreak = startBreakRaw !== '-' ? new Date(startBreakRaw).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '-';
                    const endBreak = endBreakRaw !== '-' ? new Date(endBreakRaw).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '-';
                    const dateArrived = flight['date-arrived'] || '-';
                    
                    const timeArrivedRaw = flight['time-arrived'] || '-';
                    let timeArrived = '-';
                    if (timeArrivedRaw !== '-') {
                        // Ensure it's in a parseable format by appending seconds if missing
                        const timeStr = timeArrivedRaw.length === 5 ? `${timeArrivedRaw}:00` : timeArrivedRaw;
                        const dummyDate = new Date(`1970-01-01T${timeStr}`);
                        if (!isNaN(dummyDate)) {
                            timeArrived = dummyDate.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
                        } else {
                            timeArrived = timeArrivedRaw;
                        }
                    }

                    const remarks = flight.remarks || '-';
                    const status = flight.status || 'Active';

                    tr.innerHTML = `
                        <td style="text-align: center; color: #94a3b8; font-weight: 500;">${index + 1}</td>
                        <td style="white-space: nowrap;">
                            <span style="font-weight:600; color:#334155;">${carrier}</span> <span style="color:#64748b;">${number}</span>
                        </td>
                        <td style="text-align: center; font-weight: 500;">${breakVal}</td>
                        <td style="text-align: center; font-weight: 500;">${noBreakVal}</td>
                        <td style="white-space: nowrap; color:#64748b;">${dateArrived !== '-' ? new Date(dateArrived + 'T12:00:00').toLocaleDateString() : '-'}</td>
                        <td style="white-space: nowrap; color:#64748b;">${timeArrived}</td>
                        <td style="white-space: nowrap; color:#0f172a; font-weight: 500;">${startBreak}</td>
                        <td style="white-space: nowrap; color:#0f172a; font-weight: 500;">${endBreak}</td>
                        <td style="width: 100%; max-width: 0;"><span style="font-size:12px; color:#64748b; display:block; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; width: 100%;" title="${remarks}">${remarks}</span></td>
                        <td style="white-space: nowrap;"><span class="status-${(status || '').toLowerCase()}">${status || 'Waiting'}</span></td>
                    `;
                    tr.style.cursor = 'pointer';
                    
                    // Add click event for flight drawer
                    tr.addEventListener('click', async () => {
                        openFlightDrawer(flight);
                    });

                    flightsTableBody.appendChild(tr);
                });

                // Funcionalidad de búsqueda local
                const searchInput = document.getElementById('flight-search');
                if (searchInput) {
                    searchInput.addEventListener('keyup', function() {
                        const term = this.value.toLowerCase();
                        const rows = flightsTableBody.querySelectorAll('tr');
                        rows.forEach(row => {
                            if (row.querySelector('.loading-td')) return; // No filtrar loading state
                            const text = row.textContent.toLowerCase();
                            row.style.display = text.includes(term) ? '' : 'none';
                        });
                    });
                }
            }

            // ---------- LÓGICA DEL FLIGHT DRAWER ----------
            let currentFlightForDrawer = null;
            const flightDrawer = document.getElementById('flight-drawer');
            const flightDrawerOverlay = document.getElementById('flight-drawer-overlay');
            const closeFlightDrawerBtn = document.getElementById('close-flight-drawer-btn');
            
            const editFlightStatusBtn = document.getElementById('edit-flight-status-btn');
            const saveFlightStatusBtn = document.getElementById('save-flight-status-btn');
            const cancelFlightStatusBtn = document.getElementById('cancel-flight-status-btn');
            const drawerFlightStatusSpan = document.getElementById('drawer-flight-status');
            const drawerFlightStatusEdit = document.getElementById('drawer-flight-status-edit');

            if (editFlightStatusBtn) {
                editFlightStatusBtn.addEventListener('click', () => {
                    drawerFlightStatusSpan.style.display = 'none';
                    editFlightStatusBtn.style.display = 'none';
                    drawerFlightStatusEdit.style.display = 'inline-block';
                    saveFlightStatusBtn.style.display = 'inline-block';
                    cancelFlightStatusBtn.style.display = 'inline-block';
                    drawerFlightStatusEdit.value = currentFlightForDrawer?.status || 'Waiting';
                });
            }

            if (cancelFlightStatusBtn) {
                cancelFlightStatusBtn.addEventListener('click', () => {
                    drawerFlightStatusSpan.style.display = 'inline-block';
                    editFlightStatusBtn.style.display = (typeof flightEditSwitch !== 'undefined' && flightEditSwitch && flightEditSwitch.checked) ? 'inline-block' : 'none';
                    drawerFlightStatusEdit.style.display = 'none';
                    saveFlightStatusBtn.style.display = 'none';
                    cancelFlightStatusBtn.style.display = 'none';
                });
            }

            if (saveFlightStatusBtn) {
                saveFlightStatusBtn.addEventListener('click', async () => {
                    if (!currentFlightForDrawer) return;
                    const newStatus = drawerFlightStatusEdit.value;
                    const originalText = saveFlightStatusBtn.textContent;
                    saveFlightStatusBtn.textContent = '...';
                    saveFlightStatusBtn.disabled = true;

                    try {
                        let updateRes = await supabaseClient
                            .from('Flight')
                            .update({ status: newStatus })
                            .eq('id', currentFlightForDrawer.id);
                        
                        if (updateRes.error) {
                            // Try lowercase 'flights' table as fallback just in case
                            console.log("Error updating 'Flight' table status. Trying 'flights' table...", updateRes.error.message);
                            updateRes = await supabaseClient
                                .from('flights')
                                .update({ status: newStatus })
                                .eq('id', currentFlightForDrawer.id);
                            
                            if (updateRes.error) throw updateRes.error;
                        }

                        currentFlightForDrawer.status = newStatus;
                        drawerFlightStatusSpan.innerHTML = `<span class="status-${newStatus.toLowerCase()}">${newStatus}</span>`;
                        
                        // Close edit mode
                        drawerFlightStatusSpan.style.display = 'inline-block';
                        editFlightStatusBtn.style.display = (typeof flightEditSwitch !== 'undefined' && flightEditSwitch && flightEditSwitch.checked) ? 'inline-block' : 'none';
                        drawerFlightStatusEdit.style.display = 'none';
                        saveFlightStatusBtn.style.display = 'none';
                        cancelFlightStatusBtn.style.display = 'none';

                        // Refresh flights table if it's visible or function exists
                        if (typeof window.fetchFlights === 'function') {
                            window.fetchFlights();
                        }
                    } catch (err) {
                        console.error("Error updating flight status:", err);
                        alert("Could not update flight status.");
                    } finally {
                        saveFlightStatusBtn.textContent = originalText;
                        saveFlightStatusBtn.disabled = false;
                    }
                });
            }

            // --- EDIT MODE SWITCH LOGIC ---
            const flightEditSwitch = document.getElementById('flight-edit-mode-switch');
            if (flightEditSwitch) {
                flightEditSwitch.addEventListener('change', (e) => {
                    const isEdit = e.target.checked;
                    const icons = document.querySelectorAll('.flight-drawer-edit-icon');
                    
                    icons.forEach(icon => {
                        // Check if its corresponding span is visible to avoid overwriting active edits
                        // Usually the span is the direct left sibling or close previous sibling
                        const parent = icon.parentElement;
                        let isSpanVisible = true;
                        if (parent) {
                            const span = parent.querySelector('span[id^="drawer-flight-"]');
                            if (span && span.style.display === 'none') {
                                isSpanVisible = false;
                            }
                        }
                        
                        if (isEdit && isSpanVisible) {
                            icon.style.display = 'inline-block';
                        } else {
                            icon.style.display = 'none';
                            // Note: We don't forcefully auto-cancel. If they toggle edit mode off, 
                            // they just won't be able to start new edits. Existing edits wait for Save/Cancel.
                        }
                    });
                });
            }

            function setupTimeEditField(fieldId, dbFieldName) {
                const editBtn = document.getElementById(`edit-flight-${fieldId}-btn`);
                const saveBtn = document.getElementById(`save-flight-${fieldId}-btn`);
                const cancelBtn = document.getElementById(`cancel-flight-${fieldId}-btn`);
                const spanEl = document.getElementById(`drawer-flight-${fieldId}`);
                const inputEl = document.getElementById(`drawer-flight-${fieldId}-edit`);

                if (editBtn) {
                    editBtn.addEventListener('click', () => {
                        spanEl.style.display = 'none';
                        editBtn.style.display = 'none';
                        inputEl.style.display = 'inline-block';
                        saveBtn.style.display = 'inline-block';
                        cancelBtn.style.display = 'inline-block';
                        
                        let val = currentFlightForDrawer?.[dbFieldName];
                        let timeVal = '';
                        if (val && val !== '-') {
                            const d = new Date(val);
                            if (!isNaN(d.getTime())) {
                                timeVal = new Intl.DateTimeFormat('en-GB', {
                                    timeZone: 'America/Chicago',
                                    hour: '2-digit', minute: '2-digit', second: '2-digit'
                                }).format(d);
                            }
                        }
                        inputEl.value = timeVal;
                    });
                }

                if (cancelBtn) {
                    cancelBtn.addEventListener('click', () => {
                        spanEl.style.display = 'inline-block';
                        editBtn.style.display = (typeof flightEditSwitch !== 'undefined' && flightEditSwitch && flightEditSwitch.checked) ? 'inline-block' : 'none';
                        inputEl.style.display = 'none';
                        saveBtn.style.display = 'none';
                        cancelBtn.style.display = 'none';
                    });
                }

                if (saveBtn) {
                    saveBtn.addEventListener('click', async () => {
                        if (!currentFlightForDrawer) return;
                        let newTimeValue = inputEl.value; // "HH:MM" or "HH:MM:SS"
                        const originalText = saveBtn.textContent;
                        saveBtn.textContent = '...';
                        saveBtn.disabled = true;

                        let fullTimestamp = null;
                        if (newTimeValue) {
                            if (newTimeValue.length === 5) newTimeValue += ':00';
                            
                            let datePart = '';
                            const existingVal = currentFlightForDrawer[dbFieldName];
                            if (existingVal && existingVal !== '-') {
                                datePart = existingVal.split('T')[0];
                            } else {
                                const dateArrived = currentFlightForDrawer['date-arrived'];
                                if (dateArrived) {
                                    datePart = dateArrived;
                                } else {
                                    const formatter = new Intl.DateTimeFormat('en-US', {
                                        timeZone: 'America/Chicago',
                                        year: 'numeric', month: '2-digit', day: '2-digit'
                                    });
                                    const p = {};
                                    formatter.formatToParts(new Date()).forEach(part => p[part.type] = part.value);
                                    datePart = `${p.year}-${p.month}-${p.day}`;
                                }
                            }
                            fullTimestamp = `${datePart}T${newTimeValue}`;
                        } else {
                            fullTimestamp = null;
                        }

                        let updatePayload = {};
                        updatePayload[dbFieldName] = fullTimestamp;

                        try {
                            let updateRes = await supabaseClient
                                .from('Flight')
                                .update(updatePayload)
                                .eq('id', currentFlightForDrawer.id);
                            
                            if (updateRes.error) {
                                updateRes = await supabaseClient
                                    .from('flights')
                                    .update(updatePayload)
                                    .eq('id', currentFlightForDrawer.id);
                                
                                if (updateRes.error) throw updateRes.error;
                            }

                            currentFlightForDrawer[dbFieldName] = fullTimestamp;
                            spanEl.textContent = fullTimestamp ? new Date(fullTimestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '--';
                            
                            // Close edit mode
                            spanEl.style.display = 'inline-block';
                            editBtn.style.display = (typeof flightEditSwitch !== 'undefined' && flightEditSwitch && flightEditSwitch.checked) ? 'inline-block' : 'none';
                            inputEl.style.display = 'none';
                            saveBtn.style.display = 'none';
                            cancelBtn.style.display = 'none';

                            if (typeof window.fetchFlights === 'function') window.fetchFlights();
                        } catch (err) {
                            console.error(`Error updating flight ${dbFieldName}:`, err);
                            alert(`Could not update flight ${dbFieldName}.`);
                        } finally {
                            saveBtn.textContent = originalText;
                            saveBtn.disabled = false;
                        }
                    });
                }
            }

            // Function generator for simple edit inputs to avoid repeated boilerplate
            function setupDrawerFieldEdit(fieldId, dbFieldName) {
                const editBtn = document.getElementById(`edit-flight-${fieldId}-btn`);
                const saveBtn = document.getElementById(`save-flight-${fieldId}-btn`);
                const cancelBtn = document.getElementById(`cancel-flight-${fieldId}-btn`);
                const spanEl = document.getElementById(`drawer-flight-${fieldId}`);
                const inputEl = document.getElementById(`drawer-flight-${fieldId}-edit`);
                const autoLabel = document.getElementById(`drawer-flight-${fieldId}-auto-label`);
                const autoSwitch = document.getElementById(`drawer-flight-${fieldId}-auto-switch`);

                if (autoSwitch) {
                    autoSwitch.addEventListener('change', (e) => {
                        inputEl.disabled = e.target.checked;
                        inputEl.style.opacity = e.target.checked ? '0.5' : '1';
                        inputEl.placeholder = e.target.checked ? 'Auto' : '';
                        if (e.target.checked) inputEl.value = '';
                        if (!e.target.checked) inputEl.focus();
                    });
                }

                if (editBtn) {
                    editBtn.addEventListener('click', () => {
                        spanEl.style.display = 'none';
                        editBtn.style.display = 'none';
                        inputEl.style.display = 'inline-block';
                        saveBtn.style.display = 'inline-block';
                        cancelBtn.style.display = 'inline-block';
                        
                        if (autoLabel) {
                            autoLabel.style.display = 'flex';
                            autoSwitch.checked = true;
                            inputEl.disabled = true;
                            inputEl.style.opacity = '0.5';
                            inputEl.placeholder = 'Auto';
                        }
                        
                        const val = currentFlightForDrawer?.[dbFieldName];
                        inputEl.value = (val !== null && val !== undefined && val !== '-') ? val : '';
                    });
                }

                if (cancelBtn) {
                    cancelBtn.addEventListener('click', () => {
                        spanEl.style.display = 'inline-block';
                        // Keep edit button hidden if switch is off
                        editBtn.style.display = flightEditSwitch && flightEditSwitch.checked ? 'inline-block' : 'none';
                        inputEl.style.display = 'none';
                        saveBtn.style.display = 'none';
                        cancelBtn.style.display = 'none';
                        if (autoLabel) autoLabel.style.display = 'none';
                    });
                }

                if (saveBtn) {
                    saveBtn.addEventListener('click', async () => {
                        if (!currentFlightForDrawer) return;
                        let newVal = inputEl.value;
                        const originalText = saveBtn.textContent;
                        saveBtn.textContent = '...';
                        saveBtn.disabled = true;

                        let updatePayload = {};
                        updatePayload[dbFieldName] = newVal;

                        try {
                            let updateRes = await supabaseClient
                                .from('Flight')
                                .update(updatePayload)
                                .eq('id', currentFlightForDrawer.id);
                            
                            if (updateRes.error) {
                                updateRes = await supabaseClient
                                    .from('flights')
                                    .update(updatePayload)
                                    .eq('id', currentFlightForDrawer.id);
                                
                                if (updateRes.error) throw updateRes.error;
                            }

                            currentFlightForDrawer[dbFieldName] = newVal;
                            spanEl.textContent = newVal || '--';
                            
                            // Close edit mode
                            spanEl.style.display = 'inline-block';
                            editBtn.style.display = flightEditSwitch && flightEditSwitch.checked ? 'inline-block' : 'none';
                            inputEl.style.display = 'none';
                            saveBtn.style.display = 'none';
                            cancelBtn.style.display = 'none';
                            if (autoLabel) autoLabel.style.display = 'none';

                            if (typeof window.fetchFlights === 'function') window.fetchFlights();
                        } catch (err) {
                            console.error(`Error updating flight ${dbFieldName}:`, err);
                            alert(`Could not update flight ${dbFieldName}.`);
                        } finally {
                            saveBtn.textContent = originalText;
                            saveBtn.disabled = false;
                        }
                    });
                }
            }

            // Setup new editable fields
            setupDrawerFieldEdit('cbreak', 'cant-break');
            setupDrawerFieldEdit('cno', 'cant-noBreak');
            setupDrawerFieldEdit('rem', 'remarks');

            setupTimeEditField('firsttruck', 'first-truck');
            setupTimeEditField('lasttruck', 'last-truck');
            setupTimeEditField('startbreak', 'start-break');
            setupTimeEditField('endbreak', 'end-break');

            if (closeFlightDrawerBtn) {
                closeFlightDrawerBtn.addEventListener('click', () => {
                    flightDrawer.style.right = '-800px';
                    flightDrawerOverlay.classList.remove('open');
                    if (flightEditSwitch && flightEditSwitch.checked) {
                        flightEditSwitch.checked = false;
                        flightEditSwitch.dispatchEvent(new Event('change'));
                    }
                });
            }
            if (flightDrawerOverlay) {
                flightDrawerOverlay.addEventListener('click', () => {
                    flightDrawer.style.right = '-800px';
                    flightDrawerOverlay.classList.remove('open');
                    if (flightEditSwitch && flightEditSwitch.checked) {
                        flightEditSwitch.checked = false;
                        flightEditSwitch.dispatchEvent(new Event('change'));
                    }
                });
            }

            async function openFlightDrawer(flight) {
                currentFlightForDrawer = flight;
                
                // Reset global edit switch
                if (flightEditSwitch) {
                    flightEditSwitch.checked = false;
                    const event = new Event('change');
                    flightEditSwitch.dispatchEvent(event);
                }

                // Function to reset individual edit states
                function resetEditState(fieldId) {
                    const spanEl = document.getElementById(`drawer-flight-${fieldId}`);
                    const editBtn = document.getElementById(`edit-flight-${fieldId}-btn`);
                    const inputEl = document.getElementById(`drawer-flight-${fieldId}-edit`);
                    const saveBtn = document.getElementById(`save-flight-${fieldId}-btn`);
                    const cancelBtn = document.getElementById(`cancel-flight-${fieldId}-btn`);
                    const autoLabel = document.getElementById(`drawer-flight-${fieldId}-auto-label`);

                    if (spanEl && editBtn && inputEl && saveBtn && cancelBtn) {
                        spanEl.style.display = 'inline-block';
                        editBtn.style.display = 'none'; // Since switch is always off when drawer opens
                        inputEl.style.display = 'none';
                        saveBtn.style.display = 'none';
                        cancelBtn.style.display = 'none';
                        if (autoLabel) autoLabel.style.display = 'none';
                    }
                }

                resetEditState('status');
                resetEditState('startbreak');
                resetEditState('endbreak');
                resetEditState('firsttruck');
                resetEditState('lasttruck');
                resetEditState('cbreak');
                resetEditState('cno');
                resetEditState('rem');

                // Formatting reference
                const carrier = flight.carrier || '';
                const number = flight.number || '';
                const dateArrivedRaw = flight['date-arrived'];
                const fDateStr = dateArrivedRaw ? new Date(dateArrivedRaw + 'T12:00:00').toLocaleDateString() : '';
                const flightRefString = `${carrier} ${number} ${fDateStr}`.trim();
                
                const startBreakRaw = flight['start-break'] || '-';
                const endBreakRaw = flight['end-break'] || '-';
                const firstTruckRaw = flight['first-truck'] || '-';
                const lastTruckRaw = flight['last-truck'] || '-';

                const startBreak = startBreakRaw !== '-' ? new Date(startBreakRaw).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '-';
                const endBreak = endBreakRaw !== '-' ? new Date(endBreakRaw).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '-';
                const firstTruck = firstTruckRaw !== '-' ? new Date(firstTruckRaw).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '--';
                const lastTruck = lastTruckRaw !== '-' ? new Date(lastTruckRaw).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : '--';

                // Set Header Metadata
                document.getElementById('drawer-flight-title').textContent = `Flight: ${carrier} ${number}`;
                const safeStatus = flight.status || 'Waiting';
                document.getElementById('drawer-flight-status').innerHTML = `<span class="status-${safeStatus.toLowerCase()}">${safeStatus}</span>`;
                document.getElementById('drawer-flight-date').textContent = fDateStr || '--';
                if(document.getElementById('drawer-flight-startbreak')) document.getElementById('drawer-flight-startbreak').textContent = startBreak;
                if(document.getElementById('drawer-flight-endbreak')) document.getElementById('drawer-flight-endbreak').textContent = endBreak;
                
                if(document.getElementById('drawer-flight-firsttruck')) document.getElementById('drawer-flight-firsttruck').textContent = firstTruck;
                if(document.getElementById('drawer-flight-lasttruck')) document.getElementById('drawer-flight-lasttruck').textContent = lastTruck;

                document.getElementById('drawer-flight-cbreak').textContent = flight['cant-break'] || '0';
                document.getElementById('drawer-flight-cno').textContent = flight['cant-noBreak'] || '0';
                document.getElementById('drawer-flight-rem').textContent = flight.remarks || '--';

                const contentList = document.getElementById('drawer-flight-content-list');
                contentList.innerHTML = '<div style="text-align:center; padding: 20px;"><span class="loading-td" style="color:#64748b;">Loading ULDs...</span></div>';

                // Open Drawer Animation
                flightDrawerOverlay.classList.add('open');
                flightDrawer.style.right = '0';

                // Fetch Database contents
                try {
                    const { data: ulds, error: uldErr } = await supabaseClient
                        .from('ULD')
                        .select('*')
                        .eq('refCarrier', carrier)
                        .eq('refNumber', number)
                        .eq('refDate', dateArrivedRaw);

                    if (uldErr) throw uldErr;

                    if (!ulds || ulds.length === 0) {
                        contentList.innerHTML = '<div style="text-align: center; color: #94a3b8; font-size: 13px; font-style: italic; padding: 20px;">No ULDs found directly linked to this flight.</div>';
                        return;
                    }

                    // Build string
                    contentList.innerHTML = '';
                    let uldIndex = 1;

                    for (const uld of ulds) {
                        const uldNum = uld['ULD number'] || uld.uldNumber || uld.id || 'Unknown';
                        const uHeader = document.createElement('div');
                        uHeader.style.cssText = 'background: #f1f5f9; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; margin-bottom: 8px;';
                        
                        // ULD Metadata
                        let headerHtml = `
                            <div style="display:flex; justify-content:space-between; align-items:center; cursor:pointer;" onclick="const n=this.nextElementSibling; if(n.style.display==='none'){n.style.display='block'; this.querySelector('.fa-chevron-right').style.transform='rotate(90deg)';}else{n.style.display='none'; this.querySelector('.fa-chevron-right').style.transform='rotate(0deg)';}">
                                <div style="display:flex; align-items:center; gap: 8px;">
                                    <i class="fas fa-chevron-right" style="color: #94a3b8; font-size: 10px; transition: transform 0.2s;"></i>
                                    <strong style="color: #0f172a; font-size: 13px;">${uldIndex}. ULD: ${uldNum}</strong>
                                </div>
                                <span style="font-size: 11px; background: #cbd5e1; padding: 2px 6px; border-radius: 4px; color: #334155;">Pcs: ${uld.pieces || 0} &nbsp;|&nbsp; Wgt: ${uld.weight || 0}</span>
                            </div>
                        `;
                        uldIndex++;

                        // Fetch AWBs nested within this ULD from Supabase
                        const { data: awbs, error: awbErr } = await supabaseClient.from('AWB').select('*');
                        
                        let matchedAwbs = [];
                        if (awbs && !awbErr) {
                            const fCarrier = carrier || '';
                            const fNumber = number || '';
                            const fDateRaw = dateArrivedRaw || '';
                            const refDate = fDateRaw ? fDateRaw.split('T')[0] : '';
                            const strictFlightRefString = `${fCarrier} ${fNumber} ${refDate}`.trim();
                            const partialFlightRef = `${fCarrier} ${fNumber}`.trim();

                            awbs.forEach(awbDoc => {
                                let nestedArr = [];
                                if (Array.isArray(awbDoc['data-AWB'])) {
                                    nestedArr = awbDoc['data-AWB'];
                                } else if (awbDoc['data-AWB']) {
                                    try { nestedArr = JSON.parse(awbDoc['data-AWB']); } catch(e){}
                                }
                                
                                if (nestedArr.length > 0) {
                                    nestedArr.forEach(nested => {
                                        const nUld = String(nested.refULD || '').trim().toLowerCase();
                                        const tUld = String(uldNum || '').trim().toLowerCase();
                                        
                                        if (nUld !== tUld) return;

                                        const nCarrier = String(nested.refCarrier || '').trim().toLowerCase();
                                        const nNumber = String(nested.refNumber || '').replace(/^0+/, '').trim().toLowerCase();
                                        const nDate = String(nested.refDate || '').trim().toLowerCase();
                                        
                                        const tCarrier = String(fCarrier || '').trim().toLowerCase();
                                        const tNumber = String(fNumber || '').replace(/^0+/, '').trim().toLowerCase();
                                        const tDate = String(refDate || '').trim().toLowerCase();
                                        
                                        let sameFlight = false;

                                        if (nCarrier || nNumber) {
                                            const sameDate = (nDate === tDate || (nDate && tDate.includes(nDate)) || (tDate && nDate.includes(tDate)) || !tDate);
                                            sameFlight = (!tCarrier || nCarrier === tCarrier) && (!tNumber || nNumber === tNumber) && sameDate;
                                        } else if (nested.refFlight) {
                                            const nFlight = String(nested.refFlight || '').trim().toLowerCase();
                                            const strictF = String(strictFlightRefString || '').trim().toLowerCase();
                                            const partialF = String(partialFlightRef || '').trim().toLowerCase();
                                            
                                            if (nFlight === strictF || nFlight.includes(partialF)) sameFlight = true;
                                        }

                                        if (sameFlight) {
                                            let existingCoordObj = null;
                                            if (awbDoc['data-coordinator']) {
                                                let cArr = [];
                                                if (Array.isArray(awbDoc['data-coordinator'])) cArr = awbDoc['data-coordinator'];
                                                else {
                                                    try { cArr = JSON.parse(awbDoc['data-coordinator']); } catch(e){}
                                                }
                                                if (Array.isArray(cArr)) {
                                                    const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                                                    const eqNum = (a, b) => String(a || '').replace(/^0+/, '').trim().toLowerCase() === String(b || '').replace(/^0+/, '').trim().toLowerCase();
                                                    existingCoordObj = cArr.find(c => 
                                                        eqRef(c.refCarrier, fCarrier) &&
                                                        eqNum(c.refNumber, fNumber) &&
                                                        eqRef(c.refDate, refDate) &&
                                                        eqRef(c.refULD, uldNum)
                                                    );
                                                }
                                            }

                                            let existingLocObj = null;
                                            if (awbDoc['data-location']) {
                                                let lArr = [];
                                                if (Array.isArray(awbDoc['data-location'])) lArr = awbDoc['data-location'];
                                                else {
                                                    try { lArr = JSON.parse(awbDoc['data-location']); } catch(e){}
                                                }
                                                if (Array.isArray(lArr)) {
                                                    const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                                                    const eqNum = (a, b) => String(a || '').replace(/^0+/, '').trim().toLowerCase() === String(b || '').replace(/^0+/, '').trim().toLowerCase();
                                                    existingLocObj = lArr.find(c => 
                                                        eqRef(c.refCarrier, fCarrier) &&
                                                        eqNum(c.refNumber, fNumber) &&
                                                        eqRef(c.refDate, refDate) &&
                                                        eqRef(c.refULD, uldNum)
                                                    );
                                                }
                                            }

                                            matchedAwbs.push({
                                                id: awbDoc.id,
                                                number: awbDoc['AWB number'] || awbDoc.awb_number || 'Unknown',
                                                pieces: nested.pieces,
                                                weight: nested.weight,
                                                total: awbDoc.total,
                                                remarks: nested.remarks,
                                                houses: nested.house_number || [],
                                                refCarrier: fCarrier,
                                                refNumber: fNumber,
                                                refDate: refDate,
                                                refULD: uldNum,
                                                coordData: existingCoordObj,
                                                locData: existingLocObj
                                            });
                                        }
                                    });
                                }
                            });
                        }

                        let awbsHtml = '';
                        if (matchedAwbs.length === 0) {
                            awbsHtml += '<div style="font-size: 13px; color: #64748b; font-style: italic; background:#f8fafc; padding:12px; border-radius:6px;">No AWBs associated or logged under this PMC format.</div>';
                        } else {
                            awbsHtml += `
                                <table style="width: 100%; border-collapse: collapse; text-align: left; background:#fafafa; border-radius: 6px; overflow: hidden; border:1px solid #f1f5f9; margin-top:8px;">
                                    <thead style="background: #f1f5f9;">
                                        <tr>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; width: 140px; white-space: nowrap;">AWB Number</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 50px;">Pcs</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 50px;">Total</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 70px;">Weight</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 60px;">Houses</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 90px;">Issues</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 90px;">Status</th>
                                            <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; width: 100%;">Remarks</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                            `;
                            
                            matchedAwbs.forEach((ma, index) => {
                                const hCount = ma.houses.length;
                                const safeHStr = ma.houses.join(', ').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                const hBadge = hCount > 0 ? `<span style="background:#e0e7ff; color:#4f46e5; padding:2px 8px; border-radius:10px; font-size:10px; font-weight:600; cursor:pointer;" onclick="event.stopPropagation(); window.showHouseNumbersModal('${safeHStr}')" title="Click to view all houses">${hCount}</span>` : '<span style="color:#94a3b8; font-size:10px;">0</span>';
                                const remEscaped = (ma.remarks || '-').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                
                                let encodedData = '';
                                let encodedLocs = '';
                                let mismatchBadge = '<span style="color:#cbd5e1; font-size: 10px;">-</span>';
                                
                                if (ma.coordData) {
                                    encodedData = encodeURIComponent(JSON.stringify(ma.coordData));
                                    if (ma.coordData['Mismatch Report'] && ma.coordData['Mismatch Report'].trim() !== '') {
                                        const safeReport = ma.coordData['Mismatch Report'].replace(/'/g, "\\'").replace(/"/g, '&quot;').replace(/\n/g, '\\n');
                                        mismatchBadge = `<span style="background:#fef08a; color:#854d0e; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:700; cursor: pointer; box-shadow: 0 2px 4px rgba(250,204,21,0.2); display: inline-flex; align-items: center;" title="Click to view explanation" onclick="event.stopPropagation(); window.viewMismatchReport('${safeReport}')"><i class="fas fa-exclamation-triangle" style="margin-right:4px;"></i> REPORT</span>`;
                                    }
                                }
                                if (ma.locData) encodedLocs = encodeURIComponent(JSON.stringify(ma.locData));
                                
                                const isFlightChecked = flight.status === 'Checked' || flight.status === 'Chequeado';
                                
                                let checkedBg = '#f1f5f9';
                                let statusBadge = `<span style="background:#e2e8f0; color:#64748b; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:600;">PENDING</span>`;
                                
                                if (ma.coordData) {
                                    checkedBg = '#ecfdf5';
                                    let checkedBy = (ma.coordData.checkedBy || 'Unknown User').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                    let checkedAt = ma.coordData.checkedAt ? new Date(ma.coordData.checkedAt).toLocaleString().replace(/'/g, "\\'").replace(/"/g, '&quot;') : 'Unknown Time';
                                    statusBadge = `<span style="background:#10b981; color:white; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:700; box-shadow: 0 2px 4px rgba(16,185,129,0.2); cursor: pointer;" onclick="event.stopPropagation(); window.showCoordinatorCheckInfo('${checkedBy}', '${checkedAt}')"><i class="fas fa-check" style="margin-right:3px;"></i> CHECKED</span>`;
                                }

                                awbsHtml += `
                                    <tr style="transition: background 0.2s; background: transparent;">
                                        <td style="padding: 10px 12px; font-size: 13px; color: #0f172a; font-weight: 600; border-bottom: 1px solid ${checkedBg}; white-space: nowrap;">
                                            ${ma.number}
                                        </td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${ma.pieces || 0}</td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #0f172a; border-bottom: 1px solid ${checkedBg}; text-align: center; font-weight: 700;">${ma.total || 0}</td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${ma.weight || 0}</td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${hBadge}</td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${mismatchBadge}</td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${statusBadge}</td>
                                        <td style="padding: 10px 12px; font-size: 12px; color: #64748b; border-bottom: 1px solid ${checkedBg}; max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${remEscaped}">
                                            ${ma.remarks || '-'}
                                        </td>
                                    </tr>
                                `;
                            });
                            awbsHtml += `</tbody></table>`;
                        }

                        uHeader.innerHTML = headerHtml + `<div style="display:none; margin-top: 12px; padding-top: 12px; border-top: 1px dashed #cbd5e1;">${awbsHtml}</div>`;
                        contentList.appendChild(uHeader);
                    }
                    
                } catch (err) {
                    console.error("Error drawing flight uld/awb info:", err);
                    contentList.innerHTML = '<div style="text-align: center; color: red; font-size: 13px; font-style: italic; padding: 20px;">Could not load data. Check console.</div>';
                }
            }

            function renderDemoFlights() {
                flightsTableBody.innerHTML = '<tr><td colspan="10" style="text-align:center; padding: 20px; color: #94a3b8;">No flights available.</td></tr>';
            }

            window.fetchFlights();
        }
        // ---------- FIN LÓGICA DE VUELOS ----------

        // ---------- LÓGICA AÑADIR VUELO Y ULDs ----------
        const addFlightForm = document.getElementById('add-flight-form');
        let localUlds = []; // Array temporal (Legacy para AWB drawer temporalmente si se requiere)

        window.getULDStatusBadgeHtml = function(rawStatus) {
            let status = (rawStatus || 'received').toLowerCase();
            const badgeStyle = "padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: 600; display: inline-block; width: 75px; text-align: center; box-sizing: border-box;";
            switch(status) {
                case 'waiting': return `<span style="background: #f1f5f9; color: #475569; ${badgeStyle}">Waiting</span>`;
                case 'pending': return `<span style="background: #fef08a; color: #854d0e; ${badgeStyle}">Pending</span>`;
                case 'saved': return `<span style="background: #bae6fd; color: #0369a1; ${badgeStyle}">Saved</span>`;
                case 'ready': return `<span style="background: #bbf7d0; color: #166534; ${badgeStyle}">Ready</span>`;
                case 'checked': return `<span style="background: #e9d5ff; color: #6b21a8; ${badgeStyle}">Checked</span>`;
                case 'received':
                default:
                    return `<span style="background: #e2e8f0; color: #475569; ${badgeStyle}">Received</span>`;
            }
        };

        // ====== LÓGICA DRAWER AWB (LATERAL) ======
        let currentUldIdForAwb = null;
        let currentReadOnlyUldId = null;
        const awbDrawer = document.getElementById('awb-drawer');
        const awbOverlay = document.getElementById('awb-drawer-overlay');
        const closeDrawerBtn = document.getElementById('close-drawer-btn');
        const drawerUldTitle = document.getElementById('drawer-uld-title');
        const drawerUldFlightRef = document.getElementById('drawer-uld-flight-ref');
        
        const drawerUldPcs = document.getElementById('drawer-uld-pcs');
        const drawerUldWgt = document.getElementById('drawer-uld-wgt');
        const drawerUldPrio = document.getElementById('drawer-uld-prio');
        const drawerUldBrk = document.getElementById('drawer-uld-brk');
        const drawerUldSts = document.getElementById('drawer-uld-sts');
        const drawerUldRem = document.getElementById('drawer-uld-rem');

        const drawerAwbTable = document.getElementById('drawer-awb-table-body');
        const addAwbBtn = document.getElementById('add-awb-btn');

        // Función abrir panel
        window.openAwbPanel = function(uldId) {
            currentUldIdForAwb = uldId;
            const uld = localUlds.find(u => u.id == uldId || u["ULD number"] == uldId || u.uld_number == uldId);
            if(!uld) return;

            drawerUldTitle.textContent = `ULD: ${uld["ULD number"] || uld.uld_number || uld.id}`;
            
            if (drawerUldFlightRef) {
                if (uld.refCarrier || uld.refNumber) {
                    const carrier = uld.refCarrier || '';
                    const number = uld.refNumber || '';
                    const date = uld.refDate ? new Date(uld.refDate + 'T12:00:00').toLocaleDateString() : '';
                    drawerUldFlightRef.textContent = `Flight: ${carrier} ${number} ${date}`.trim();
                    drawerUldFlightRef.style.color = '#4f46e5'; // Blue
                    drawerUldFlightRef.style.display = 'block';
                } else {
                    drawerUldFlightRef.textContent = 'No Flight';
                    drawerUldFlightRef.style.color = '#ef4444'; // Red
                    drawerUldFlightRef.style.display = 'block';
                }
            }
            
            // Llenar metadatos ULD
            if(drawerUldPcs) drawerUldPcs.textContent = uld.pieces || '0';
            if(drawerUldWgt) drawerUldWgt.textContent = (uld.weight || '0') + ' kg';
            
            const isPrio = uld.isPriority || uld.priority;
            const isBrk = uld.isBreak || uld.break;

            const drawerUldPcsEdit = document.getElementById('drawer-uld-pcs-edit');
            const drawerUldWgtEdit = document.getElementById('drawer-uld-wgt-edit');
            const drawerUldPrioEdit = document.getElementById('drawer-uld-prio-edit');
            const drawerUldBrkEdit = document.getElementById('drawer-uld-brk-edit');
            const drawerUldStsEdit = document.getElementById('drawer-uld-sts-edit');
            const drawerUldRemEdit = document.getElementById('drawer-uld-rem-edit');

            if(drawerUldPcsEdit) drawerUldPcsEdit.value = uld.pieces || '';
            if(drawerUldWgtEdit) drawerUldWgtEdit.value = uld.weight || '';
            if(drawerUldPrioEdit) drawerUldPrioEdit.value = isPrio ? 'yes' : 'no';
            if(drawerUldBrkEdit) drawerUldBrkEdit.value = isBrk ? 'yes' : 'no';
            
            let cStatus = (uld.status || uld.Status || 'received').toLowerCase();
            if(drawerUldStsEdit) drawerUldStsEdit.value = cStatus;
            
            if(drawerUldRemEdit) drawerUldRemEdit.value = uld.remarks || '';
            
            if(drawerUldRem) drawerUldRem.textContent = uld.remarks || 'N/A';
            if(drawerUldPrio) drawerUldPrio.textContent = isPrio ? 'Yes' : 'No';
            if(drawerUldBrk) drawerUldBrk.textContent = isBrk ? 'Break' : 'No Break';
            if(drawerUldSts) drawerUldSts.innerHTML = window.getULDStatusBadgeHtml(cStatus);

            const uldEditModeSwitch = document.getElementById('uld-edit-mode-switch');
            if (uldEditModeSwitch) {
                uldEditModeSwitch.checked = false;
                uldEditModeSwitch.dispatchEvent(new Event('change'));
            }
            
            // Asegurar que el pie del form de AWBs y la columna de Acción se muestren
            const footer = document.getElementById('awb-drawer-footer');
            if (footer) footer.style.display = 'block';

            // Refrescar las vistas
            renderLocalAwbs();
            renderLocalUlds(); // Repintar la tabla para colocar la fila cálida activa
            
            // Abrir Drawer Animado
            awbDrawer.classList.add('open');
            awbOverlay.classList.add('open');
        };

        window.updateDrawerUldField = function(field, value) {
            if (!currentUldIdForAwb) {
                if (currentReadOnlyUldId) {
                    // Actualiza ULD global directamente en base de datos
                    const upd = {};
                    upd[field === 'pieces' ? 'pieces' : field === 'weight' ? 'weight' : field === 'priority' ? 'isPriority' : field === 'break' ? 'isBreak' : field === 'status' ? 'status' : 'remarks'] = value;
                    
                    supabaseClient.from('ULD').update(upd).eq('id', currentReadOnlyUldId).then(({error}) => {
                        if(!error && typeof window.fetchGlobalUlds === 'function') {
                            // Sincronizar UI spans estéticos aquí mismo
                            if(field === 'pieces' && drawerUldPcs) drawerUldPcs.textContent = value || '0';
                            if(field === 'weight' && drawerUldWgt) drawerUldWgt.textContent = (value || '0') + ' kg';
                            if(field === 'priority' && drawerUldPrio) drawerUldPrio.textContent = value ? 'Yes' : 'No';
                            if(field === 'break' && drawerUldBrk) drawerUldBrk.textContent = value ? 'Break' : 'No Break';
                            if(field === 'status' && drawerUldSts) drawerUldSts.innerHTML = window.getULDStatusBadgeHtml(value);
                            if(field === 'remarks' && drawerUldRem) drawerUldRem.textContent = value || 'N/A';
                            
                            window.fetchGlobalUlds();
                        } else if (error) {
                            console.error("Error updating global ULD:", error);
                        }
                    });
                }
                return;
            }
            const uldIndex = localUlds.findIndex(u => u.id == currentUldIdForAwb || u["ULD number"] == currentUldIdForAwb || u.uld_number == currentUldIdForAwb);
            const flightUldIndex = flightLocalUlds.findIndex(u => u.id == currentUldIdForAwb || u.uldNumber == currentUldIdForAwb);

            if (uldIndex > -1) {
                if(field === 'pieces') localUlds[uldIndex].pieces = value;
                else if(field === 'weight') localUlds[uldIndex].weight = value;
                else if(field === 'priority') localUlds[uldIndex].priority = value;
                else if(field === 'break') localUlds[uldIndex].break = value;
                else if(field === 'status') localUlds[uldIndex].status = value;
                else if(field === 'remarks') localUlds[uldIndex].remarks = value;
            }

            if (flightUldIndex > -1) {
                if(field === 'pieces') flightLocalUlds[flightUldIndex].pieces = value;
                else if(field === 'weight') flightLocalUlds[flightUldIndex].weight = value;
                else if(field === 'priority') {
                    flightLocalUlds[flightUldIndex].priority = value;
                    flightLocalUlds[flightUldIndex].isPriority = value;
                }
                else if(field === 'break') {
                    flightLocalUlds[flightUldIndex].break = value;
                    flightLocalUlds[flightUldIndex].isBreak = value;
                }
                else if(field === 'status') flightLocalUlds[flightUldIndex].status = value;
                else if(field === 'remarks') flightLocalUlds[flightUldIndex].remarks = value;
            }

            // Sync visual spans
            if(field === 'pieces' && drawerUldPcs) drawerUldPcs.textContent = value || '0';
            if(field === 'weight' && drawerUldWgt) drawerUldWgt.textContent = (value || '0') + ' kg';
            if(field === 'priority' && drawerUldPrio) drawerUldPrio.textContent = value ? 'Yes' : 'No';
            if(field === 'break' && drawerUldBrk) drawerUldBrk.textContent = value ? 'Break' : 'No Break';
            if(field === 'status' && drawerUldSts) drawerUldSts.innerHTML = window.getULDStatusBadgeHtml(value);
            if(field === 'remarks' && drawerUldRem) drawerUldRem.textContent = value || 'N/A';

            renderFlightLocalUlds();
            renderLocalUlds();
        };

        let currentLocalAwbItems = { agi: [], pre: [], crate: [], box: [], other: [] };

        window.renderLocalAwbItems = function() {
            let totalChecked = 0;
            const listContainer = document.getElementById('inline-awb-local-list');
            if (!listContainer) return;

            // Calculate overall total Checked
            ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                currentLocalAwbItems[type].forEach(item => {
                    totalChecked += item.qty;
                });
            });

            let html = '';
            const labelsMap = {
                agi: 'Agi Skid',
                pre: 'Pre Skid',
                crate: 'Crates',
                box: 'Boxes',
                other: 'Other'
            };

            ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                let validItems = [];
                let totalQtyForType = 0;
                currentLocalAwbItems[type].forEach((item, index) => {
                    let qty = Number(item.qty || 0);
                    if (qty <= 0) return; // Hide zero qty items
                    validItems.push({item, index});
                    totalQtyForType += qty;
                });

                if (validItems.length > 0) {
                    let groupInnerHtml = '';
                    let innerContent = '';

                    // Render the inner content for all types, so location area is drawn.
                    validItems.forEach((obj, innerPosition) => {
                        let item = obj.item;
                        let index = obj.index;
                        
                        let editQtyHtml = '';
                        if (window.awbModalReadonly || type !== 'agi') {
                            editQtyHtml = `<span style="font-size: 14px; font-weight: 700; color: #0f172a; margin-left: 8px;">${item.qty} pcs</span>`;
                        } else {
                            editQtyHtml = `<input type="number" value="${item.qty}" onchange="window.updateAgiVal(${index}, this.value)" style="width: 60px; height: 32px; background: white; border: 1px solid #e2e8f0; border-radius: 8px; text-align: center; font-size: 13px; font-weight: 600; color: #475569; outline: none; transition: all 0.2s;" onfocus="this.style.borderColor='#cbd5e1';" onblur="this.style.borderColor='#e2e8f0';" placeholder="0">`;
                        }

                        if (type !== 'agi' && !window.currentIsLocationMode) {
                            return; // skip generating this block if not in location mode
                        }
                        
                        let labelHtml = (type === 'agi') ? `<span style="font-size: 12px; color: #64748b; font-weight: 600; min-width: 20px; text-align: left;">#${innerPosition + 1}</span>` : '';

                        groupInnerHtml += `
                            <div style="display: flex; flex-direction: column; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px 12px; margin-bottom: 6px; animation: fadeIn 0.15s ease;">
                                <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                                    <div style="display: flex; align-items: center; gap: 8px; flex: 1;">
                                        ${labelHtml}
                                        ${editQtyHtml}
                                    </div>
                                    
                                    <div id="loc-area-${type}-${index}" style="display: ${window.currentIsLocationMode ? 'flex' : 'none'}; flex-direction: column; gap: 4px; justify-content: center;"></div>

                                    <button onclick="window.removeLocalAwbItem('${type}', ${index})" style="border:none; background:none; color: #94a3b8; cursor: pointer; font-size: 18px; line-height: 1; outline: none; transition: color 0.1s; padding-right: 4px; width: 24px; ${(window.awbModalReadonly || window.currentIsLocationMode || type !== 'agi') ? 'display:none;' : ''}" onmouseover="this.style.color='#ef4444'" onmouseout="this.style.color='#94a3b8'">&times;</button>
                                </div>
                            </div>
                        `;
                    });
                    
                    if (groupInnerHtml) {
                        innerContent = `
                            <div style="display: flex; flex-direction: column; border-top: 1px solid #e2e8f0; padding-top: 8px; gap: 0;">
                                ${groupInnerHtml}
                            </div>
                        `;
                    } else {
                        innerContent = '';
                    }

                    let bubbleValue = type === 'agi' ? validItems.length : totalQtyForType;

                    let headerStyle = `display: flex; align-items: center; justify-content: space-between;`;
                    if (innerContent !== '') {
                        headerStyle += ` margin-bottom: 8px;`;
                    }

                    html += `
                        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; margin-bottom: 8px; animation: fadeIn 0.2s ease;">
                            <div style="${headerStyle}">
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <div style="background: white; border: 1px solid #cbd5e1; border-radius: 12px; min-width: 32px; height: 22px; padding: 0 4px; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 11px; color: #334155;">
                                        ${bubbleValue}
                                    </div>
                                    <span style="font-weight: 700; font-size: 13px; color: #0f172a; text-transform: uppercase;">${labelsMap[type]}</span>
                                </div>
                                ${type !== 'agi' && !window.awbModalReadonly && !window.currentIsLocationMode ? `<button onclick="window.removeLocalAwbItem('${type}', 0)" style="border:none; background:none; color: #94a3b8; cursor: pointer; font-size: 18px; line-height: 1; outline: none; transition: color 0.1s; padding-right: 4px;" onmouseover="this.style.color='#ef4444'" onmouseout="this.style.color='#94a3b8'">&times;</button>` : ''}
                            </div>
                            ${innerContent}
                        </div>
                    `;
                }
            });

            listContainer.innerHTML = html;
            
            const totalEl = document.getElementById('inline-awb-total-checked');
            if (totalEl) totalEl.textContent = totalChecked;

            if (typeof window.renderPerItemLocationUI === 'function') {
                window.renderPerItemLocationUI(window.currentIsLocationMode);
            }
        };
        
        window.renderPerItemLocationUI = function(isLocMode) {
            
            let reqLoc = '';
            const selectedPill = document.querySelector('.loc-pill.selected');
            if (selectedPill && selectedPill.style.display !== 'none') {
                 if (selectedPill.textContent.trim().toLowerCase() === 'other') {
                      reqLoc = document.getElementById('inline-awb-loc-other-input')?.value.trim() || 'OTHER';
                 } else {
                      reqLoc = selectedPill.textContent.trim();
                 }
            }

            ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                if(!currentLocalAwbItems[type]) return;
                currentLocalAwbItems[type].forEach((item, index) => {
                    const container = document.getElementById(`loc-area-${type}-${index}`);
                    if (!container) return;

                    if (!item.locs) item.locs = [];
                    
                    if (isLocMode) {
                        const hasConfirmedReq = reqLoc && item.locs.includes(reqLoc);
                        const hasAnyLoc = item.locs.length > 0;
                        
                        let reqHtml = '';
                        if (window.locModalReadonly) {
                            reqHtml = ''; // Can't confirm in readonly.
                        } else if (reqLoc && !hasConfirmedReq && !hasAnyLoc) {
                            reqHtml = `
                                <div style="display: flex; gap: 8px; align-items: center; justify-content: space-between; margin-bottom: 6px; background: #fffbeb; border: 1px solid #fde68a; padding: 4px 8px; border-radius: 4px;">
                                    <div style="font-size: 11px; font-weight: 700; color: #b45309;">Req: ${reqLoc}</div>
                                    <button onclick="window.confirmItemReqLoc('${type}', ${index}, '${reqLoc.replace(/'/g, "\\'")}')" style="background: #f59e0b; color: white; border: none; border-radius: 4px; padding: 4px 10px; font-size: 11px; font-weight: 600; cursor: pointer; transition: transform 0.1s;" onmousedown="this.style.transform='scale(0.95)'" onmouseup="this.style.transform='scale(1)'">Confirm</button>
                                </div>
                            `;
                        }

                        let locsHtml = item.locs.map((l, lIdx) => {
                            let deleteBtn = window.locModalReadonly ? '' : `<button onclick="window.removeItemLoc('${type}', ${index}, ${lIdx})" style="background: none; border: none; color: ${reqLoc && l === reqLoc ? '#047857' : '#ef4444'}; font-size: 18px; font-weight: bold; cursor: pointer; padding: 0 4px; outline: none;">&times;</button>`;
                            if (reqLoc && l === reqLoc) {
                                return `
                                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 4px; background: #ecfdf5; border: 1px solid #a7f3d0; padding: 6px 8px; border-radius: 4px;">
                                        <div style="font-size: 11px; font-weight: 700; color: #065f46;"><i class="fas fa-check-circle"></i> Confirmed: ${l}</div>
                                        ${deleteBtn}
                                    </div>
                                `;
                            } else {
                                return `
                                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
                                        <span style="font-size: 11px; font-weight: 600; color: #334155;">${l}</span>
                                        ${deleteBtn}
                                    </div>
                                `;
                            }
                        }).join('');
                        
                        let listWrapper = locsHtml ? `<div style="display: flex; flex-direction: column; margin-top: 6px;">${locsHtml}</div>` : '';

                        let inputHtml = (window.locModalReadonly || hasConfirmedReq) ? '' : `
                            <div style="display: flex; gap: 4px;">
                                <input type="text" id="inp-loc-${type}-${index}" placeholder="Ej: RACK-A" onkeypress="if(event.key === 'Enter') { event.preventDefault(); window.addItemLoc('${type}', ${index}); }" style="flex: 1; min-width: 0; padding: 4px 8px; font-size: 11px; border: 1px solid #cbd5e1; border-radius: 4px; outline: none; text-transform: uppercase;">
                                <button onclick="window.addItemLoc('${type}', ${index})" style="background: #4f46e5; color: white; border: none; border-radius: 4px; padding: 0 10px; font-size: 11px; font-weight: 600; cursor: pointer; transition: transform 0.1s;" onmousedown="this.style.transform='scale(0.95)'" onmouseup="this.style.transform='scale(1)'">Add</button>
                            </div>
                        `;

                        container.innerHTML = `
                            <div style="display: flex; flex-direction: column; border-top: 1px dashed #e2e8f0; padding-top: 6px; margin-top: 4px;">
                                ${reqHtml}
                                ${inputHtml}
                                ${listWrapper}
                            </div>
                        `;
                    } else {
                         // In non-location mode (e.g., Coordinator mode), the user explicitly doesn't want to see locations
                         // So we leave the container empty.
                         container.innerHTML = '';
                    }
                });
            });

            if (isLocMode && !window.locModalReadonly) {
                let allFilled = true;
                let hasAnyItems = false;
                ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                    if(!currentLocalAwbItems[type]) return;
                    currentLocalAwbItems[type].forEach(item => {
                        if (Number(item.qty || 0) <= 0) return;
                        hasAnyItems = true;
                        if (!item.locs || item.locs.length === 0) {
                            allFilled = false;
                        }
                    });
                });

                const locCompleteBtn = document.getElementById('inline-awb-loc-complete-btn');
                if (locCompleteBtn) {
                    if (hasAnyItems && allFilled) {
                        locCompleteBtn.disabled = false;
                        locCompleteBtn.style.opacity = '1';
                        locCompleteBtn.style.cursor = 'pointer';
                    } else {
                        locCompleteBtn.disabled = true;
                        locCompleteBtn.style.opacity = '0.5';
                        locCompleteBtn.style.cursor = 'not-allowed';
                    }
                }
            }
        };

        window.confirmItemReqLoc = async function(type, index, reqLoc) {
            if (!currentLocalAwbItems[type][index].locs) currentLocalAwbItems[type][index].locs = [];
            currentLocalAwbItems[type][index].locs.push(reqLoc);
            
            // Auto hide required inputs
            const inp = document.getElementById(`inp-loc-${type}-${index}`);
            if (inp) {
                inp.parentElement.style.display = 'none';
            }
            window.renderLocalAwbItems();
        };

        window.addItemLoc = async function(type, index) {
            const inp = document.getElementById(`inp-loc-${type}-${index}`);
            if(!inp) return;
            const val = inp.value.trim().toUpperCase();
            if(!val) return;
            
            if (!currentLocalAwbItems[type][index].locs) currentLocalAwbItems[type][index].locs = [];
            currentLocalAwbItems[type][index].locs.push(val);
            inp.value = '';
            
            // Auto hide inputs if req is also there
            if (inp.parentElement) {
                 inp.parentElement.style.display = 'none';
            }
            window.renderLocalAwbItems();
        };

        window.removeItemLoc = async function(type, index, locIndex) {
            currentLocalAwbItems[type][index].locs.splice(locIndex, 1);
            window.renderLocalAwbItems();
        };

        window.saveItemLocsToDB = async function(btn) {
            const originalText = btn ? btn.innerHTML : 'Save';
            if (btn) {
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
                btn.disabled = true;
            }
            try {
                let locsMap = {};
                ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                    locsMap[type] = {};
                    currentLocalAwbItems[type].forEach((item, idx) => {
                         locsMap[type][idx] = item.locs || [];
                    });
                });
                
                const { data, error } = await supabaseClient
                    .from('AWB')
                    .select('"data-location"')
                    .eq('id', window.currentAwbEditing.id)
                    .single();
                
                if (error) throw error;
                
                let locList = data['data-location'];
                if (!Array.isArray(locList)) {
                    try { locList = JSON.parse(locList); } catch(e) {}
                    if (!Array.isArray(locList)) locList = [];
                }

                const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                const existingIndex = locList.findIndex(c => 
                    eqRef(c.refCarrier, window.currentAwbEditing.refCarrier) &&
                    eqRef(c.refNumber, window.currentAwbEditing.refNumber) &&
                    eqRef(c.refDate, window.currentAwbEditing.refDate) &&
                    eqRef(c.refULD, window.currentAwbEditing.refULD)
                );

                const { data: { session } } = await supabaseClient.auth.getSession();
                let userName = session?.user?.user_metadata?.name || session?.user?.email || 'Unknown User';
                if (session?.user?.id) {
                    try {
                        const { data: uData } = await supabaseClient.from('Users').select('full-name').eq('ref-ID', session.user.id).single();
                        if (uData && uData['full-name']) userName = uData['full-name'];
                    } catch(e){}
                }

                const formatter = new Intl.DateTimeFormat('en-US', {
                    timeZone: 'America/Chicago',
                    year: 'numeric', month: '2-digit', day: '2-digit',
                    hour: '2-digit', minute: '2-digit', second: '2-digit',
                    hour12: false
                });
                const parts = {};
                formatter.formatToParts(new Date()).forEach(part => parts[part.type] = part.value);
                const hrs = parts.hour === '24' ? '00' : parts.hour;
                const nowChicagoIso = `${parts.year}-${parts.month}-${parts.day}T${hrs}:${parts.minute}:${parts.second}`;

                const locEntry = {
                    refCarrier: window.currentAwbEditing.refCarrier,
                    refNumber: window.currentAwbEditing.refNumber,
                    refDate: window.currentAwbEditing.refDate,
                    refULD: window.currentAwbEditing.refULD,
                    itemLocations: locsMap,
                    checkedBy: userName,
                    checkedAt: nowChicagoIso
                };

                if (existingIndex > -1) {
                    locList[existingIndex] = locEntry;
                } else {
                    locList.push(locEntry);
                }
                
                const { error: updateError } = await supabaseClient
                    .from('AWB')
                    .update({ 'data-location': locList })
                    .eq('id', window.currentAwbEditing.id);
                    
                if (updateError) throw updateError;

                if (btn) {
                    btn.innerHTML = '<i class="fas fa-check"></i> Saved';
                    btn.style.background = '#10b981';
                    
                    const modalInner = document.querySelector('#inline-awb-modal .modal-content');
                    const successOverlay = document.createElement('div');
                    successOverlay.style.position = 'absolute';
                    successOverlay.style.top = '0';
                    successOverlay.style.left = '0';
                    successOverlay.style.width = '100%';
                    successOverlay.style.height = '100%';
                    successOverlay.style.backgroundColor = 'rgba(255, 255, 255, 0.95)';
                    successOverlay.style.zIndex = '9999';
                    successOverlay.style.border = '2px solid #10b981';
                    successOverlay.style.display = 'flex';
                    successOverlay.style.flexDirection = 'column';
                    successOverlay.style.justifyContent = 'center';
                    successOverlay.style.alignItems = 'center';
                    successOverlay.style.borderRadius = '16px';
                    successOverlay.style.animation = 'fadeIn 0.3s ease';
                    
                    successOverlay.innerHTML = `
                        <div style="width: 80px; height: 80px; background: #10b981; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(16, 185, 129, 0.4);">
                            <i class="fas fa-check" style="font-size: 40px; color: white;"></i>
                        </div>
                        <h2 style="color: #064e3b; margin: 0; font-size: 24px; font-weight: 700;">Guardado correctamente</h2>
                    `;
                    
                    if (modalInner) modalInner.appendChild(successOverlay);
                    
                    setTimeout(() => {
                        document.getElementById('inline-awb-modal').classList.remove('open');
                        document.getElementById('inline-awb-modal-overlay').classList.remove('open');
                        if (successOverlay.parentNode) successOverlay.parentNode.removeChild(successOverlay);
                        btn.innerHTML = originalText;
                        btn.style.background = '#4f46e5';
                        btn.disabled = false;
                        
                        if (typeof window.currentActiveUldRowRefresh === 'function') {
                            window.currentActiveUldRowRefresh();
                        }
                        
                        if (typeof window.fetchGlobalAwbs === 'function') {
                            window.fetchGlobalAwbs();
                        }
                    }, 1200);
                }

            } catch(e) {
                console.error(e);
                alert("Failed to save location updates: " + (e.message || JSON.stringify(e)));
                if (btn) {
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                }
            }
        };

        window.addLocalAwbItem = function(type, inputId) {
            if (window.awbModalReadonly) return;
            const input = document.getElementById(inputId);
            if (!input) return;
            
            const qty = parseInt(input.value, 10);
            if(isNaN(qty) || qty <= 0) return;

            if (type === 'agi') {
                currentLocalAwbItems[type].push({ qty: qty });
            } else {
                // all others are single-value only (it replaces)
                currentLocalAwbItems[type] = [{ qty }];
            }

            input.value = ''; // Reset input to empty after adding
            window.renderLocalAwbItems();
        };

        window.updateAgiVal = function(index, val) {
            if (window.awbModalReadonly) return;
            const num = parseInt(val, 10) || 0;
            if (currentLocalAwbItems.agi[index]) {
                currentLocalAwbItems.agi[index].qty = num;
                window.renderLocalAwbItems();
            }
        };

        window.removeLocalAwbItem = function(type, index) {
            if (window.awbModalReadonly) return;
            currentLocalAwbItems[type].splice(index, 1);
            window.renderLocalAwbItems();
        };

        window.renderSpecificLocations = function() {
            const list = document.getElementById('inline-loc-list');
            if (!list) return;
            list.innerHTML = '';
            if (!window.currentSpecificLocations || window.currentSpecificLocations.length === 0) {
                list.innerHTML = '<div style="font-size: 13px; color: #94a3b8; font-style: italic;">No specific locations added yet.</div>';
                return;
            }
            window.currentSpecificLocations.forEach((loc, index) => {
                const item = document.createElement('div');
                item.style = 'display: flex; justify-content: space-between; align-items: center; background: #f8fafc; padding: 8px 12px; border: 1px solid #e2e8f0; border-radius: 6px;';
                item.innerHTML = `
                    <span style="font-size: 13px; color: #0f172a; font-weight: 600; text-transform: uppercase;">${loc}</span>
                    <button onclick="window.removeSpecificLocation(${index})" title="Remove location" style="background: none; border: none; color: #ef4444; cursor: pointer; font-size: 15px; padding: 4px; display: inline-flex; align-items: center; justify-content: center; outline: none;"><i class="fas fa-trash"></i></button>
                `;
                list.appendChild(item);
            });
        };

        window.addSpecificLocation = async function() {
            const inp = document.getElementById('inline-loc-specific-input');
            if (!inp) return;
            const val = inp.value.trim().toUpperCase();
            if (!val) return;
            
            inp.disabled = true;
            const btn = inp.nextElementSibling;
            if(btn) {
                btn.disabled = true;
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
            }
            
            if (!window.currentSpecificLocations) window.currentSpecificLocations = [];
            window.currentSpecificLocations.push(val);
            window.currentAwbParsed.specificLocations = window.currentSpecificLocations;
            
            try {
                const payload = { coordData: window.currentAwbParsed };
                const { error } = await supabaseClient.from('AWB').update(payload).eq('id', window.currentAwbEditing.id);
                if (error) throw error;
                
                inp.value = '';
                // Update inline data json if it's there
                window.renderSpecificLocations();
            } catch(e) {
                console.error(e);
                window.currentSpecificLocations.pop(); // revert
                alert('Failed to save specific location.');
            } finally {
                inp.disabled = false;
                if(btn) {
                    btn.disabled = false;
                    btn.innerHTML = 'Add';
                }
                inp.focus();
            }
        };

        window.removeSpecificLocation = async function(index) {
            if (!confirm('Remove this specific location?')) return;
            const removed = window.currentSpecificLocations.splice(index, 1)[0];
            window.currentAwbParsed.specificLocations = window.currentSpecificLocations;
            
            try {
                const payload = { coordData: window.currentAwbParsed };
                const { error } = await supabaseClient.from('AWB').update(payload).eq('id', window.currentAwbEditing.id);
                if (error) throw error;
                window.renderSpecificLocations();
            } catch(e) {
                console.error(e);
                window.currentSpecificLocations.splice(index, 0, removed); // revert
                alert('Failed to remove location.');
            }
        };

        window.openInlineAwbModalText = function(awbId, num, pcs, tot, wgt, hse, rem, rCarrier, rNum, rDate, rULD, existingDataJson, existingLocsJson, isLocationMode, isFlightChecked = false, isUldReady = false) {
            window.currentAwbEditing = { 
                id: awbId, 
                num, 
                pcs: parseInt(pcs, 10) || 0,
                tot: parseFloat(tot) || 0,
                refCarrier: rCarrier, 
                refNumber: rNum, 
                refDate: rDate, 
                refULD: rULD 
            };
            
            window.currentIsLocationMode = isLocationMode === 'true' || isLocationMode === true;
            
            // Re-established default structure
            currentLocalAwbItems = { agi: [], pre: [], crate: [], box: [], other: [] };
            
            // Try populating if it was previously checked
            let parsed = null;
            if (existingDataJson) {
                try {
                    parsed = JSON.parse(decodeURIComponent(existingDataJson));
                } catch(e) {}
            }
            let parsedLocs = null;
            if (existingLocsJson && existingLocsJson !== 'undefined' && existingLocsJson !== '') {
                try { parsedLocs = JSON.parse(decodeURIComponent(existingLocsJson)); } catch(e) {}
            }

            window.currentAwbParsed = parsed || {};
            window.currentSpecificLocations = window.currentAwbParsed.specificLocations || [];
            
            let itemLocations = {};
            if (parsedLocs && parsedLocs.itemLocations) {
                 itemLocations = parsedLocs.itemLocations;
            } else if (!window.currentIsLocationMode && window.currentAwbParsed.itemLocations) { 
                 itemLocations = window.currentAwbParsed.itemLocations; // Only fallback for Coordinator view, just in case
            }

            // Defaults reset
            ['agi', 'pre', 'crate', 'box', 'other'].forEach(id => {
                const el = document.getElementById('inline-awb-input-' + id);
                if(el) el.value = '';
            });
            document.querySelectorAll('.loc-pill.selected').forEach(pill => pill.classList.remove('selected'));
            const otherInput = document.getElementById('inline-awb-loc-other-input');
            if (otherInput) {
                otherInput.style.display = 'none';
                otherInput.value = '';
            }
            
            window.awbModalReadonly = window.currentIsLocationMode ? true : (!!parsed || isFlightChecked);
            window.locModalReadonly = window.currentIsLocationMode ? (!!parsedLocs || isUldReady) : false;
            window.isCurrentUldReady = isUldReady;
            
            // Toggle edit mode globally
            const toggleReadonlyState = (isReadonly) => {
                ['agi', 'pre', 'crate', 'box', 'other'].forEach(id => {
                    const el = document.getElementById('inline-awb-input-' + id);
                    if(el) {
                        el.readOnly = isReadonly;
                        if(isReadonly) el.blur();
                    }
                });
                
                if (otherInput) {
                    otherInput.readOnly = isReadonly;
                    if(isReadonly) otherInput.blur();
                }
                
                const repEl = document.getElementById('awb-mismatch-report');
                if (repEl) {
                    repEl.readOnly = isReadonly;
                    if(isReadonly) repEl.blur();
                }

                const svBtn = document.getElementById('inline-awb-save-btn');
                const edBtn = document.getElementById('inline-awb-edit-btn');
                
                if (isReadonly) {
                    if (svBtn) svBtn.style.display = 'none';
                    if (edBtn) edBtn.style.display = (isFlightChecked || window.currentIsLocationMode) ? 'none' : 'block';
                } else {
                    if (svBtn) svBtn.style.display = (isFlightChecked || window.currentIsLocationMode) ? 'none' : 'block';
                    if (edBtn) edBtn.style.display = 'none';
                }
            };

            const toggleLocReadonlyState = (isReadonly) => {
                const locCompleteBtn = document.getElementById('inline-awb-loc-complete-btn');
                const locEditBtn = document.getElementById('inline-awb-loc-edit-btn');
                
                if (window.currentIsLocationMode) {
                    if (isReadonly) {
                        if (locCompleteBtn) locCompleteBtn.style.display = 'none';
                        if (locEditBtn) locEditBtn.style.display = window.isCurrentUldReady ? 'none' : 'block';
                    } else {
                        if (locCompleteBtn) locCompleteBtn.style.display = 'block';
                        if (locEditBtn) locEditBtn.style.display = 'none';
                    }
                } else {
                    if (locCompleteBtn) locCompleteBtn.style.display = 'none';
                    if (locEditBtn) locEditBtn.style.display = 'none';
                }
            };

            toggleReadonlyState(window.awbModalReadonly);
            toggleLocReadonlyState(window.locModalReadonly);

            // Check status element (new)
            let statusEl = document.getElementById('inline-awb-status-banner');
            if (!statusEl) {
                statusEl = document.createElement('div');
                statusEl.id = 'inline-awb-status-banner';
                const hdr = document.querySelector('.modal-hdr');
                if (hdr) hdr.insertAdjacentElement('afterbegin', statusEl);
            }
            
            // Load if exists
            if (parsed) {
                // Load agi array back into state
                if(Array.isArray(parsed['Agi skid'])) {
                    parsed['Agi skid'].forEach((qty, idx) => {
                        currentLocalAwbItems.agi.push({qty: qty, locs: itemLocations.agi && itemLocations.agi[idx] ? [...itemLocations.agi[idx]] : []});
                    });
                }
                const getCleanQtySum = (val) => {
                    if (Array.isArray(val)) return val.reduce((acc, curr) => acc + (Number(curr) || 0), 0);
                    return Number(val) || 0;
                };

                if(parsed['Pre skid']) currentLocalAwbItems.pre = [{qty: getCleanQtySum(parsed['Pre skid']), locs: itemLocations.pre && itemLocations.pre[0] ? [...itemLocations.pre[0]] : []}];
                if(parsed['Crates']) currentLocalAwbItems.crate = [{qty: getCleanQtySum(parsed['Crates']), locs: itemLocations.crate && itemLocations.crate[0] ? [...itemLocations.crate[0]] : []}];
                if(parsed['Box']) currentLocalAwbItems.box = [{qty: getCleanQtySum(parsed['Box']), locs: itemLocations.box && itemLocations.box[0] ? [...itemLocations.box[0]] : []}];
                if(parsed['Other']) currentLocalAwbItems.other = [{qty: getCleanQtySum(parsed['Other']), locs: itemLocations.other && itemLocations.other[0] ? [...itemLocations.other[0]] : []}];
                
                const repEl = document.getElementById('awb-mismatch-report');
                const mismatchContainer = document.getElementById('awb-mismatch-container');
                if (parsed['Mismatch Report']) {
                    if (repEl) repEl.value = parsed['Mismatch Report'];
                    if (mismatchContainer) mismatchContainer.style.display = 'none';
                } else {
                    if (repEl) repEl.value = '';
                    if (mismatchContainer) mismatchContainer.style.display = 'none';
                }
                
                // Location map back
                if (parsed['Location required']) {
                    const lq = parsed['Location required'].toLowerCase();
                    let matchedPill = false;
                    document.querySelectorAll('.loc-pill').forEach(pill => {
                        const txt = pill.textContent.trim().toLowerCase();
                        if (txt === lq) {
                            pill.classList.add('selected');
                            matchedPill = true;
                        }
                    });
                    if (!matchedPill && parsed['Location required'].trim() !== '') {
                        const optPill = Array.from(document.querySelectorAll('.loc-pill')).find(p => p.textContent.trim().toLowerCase() === 'other');
                        if (optPill) {
                            optPill.classList.add('selected');
                            if (otherInput) {
                                otherInput.style.display = 'block';
                                otherInput.value = parsed['Location required'];
                            }
                        }
                    }
                }
                
                statusEl.innerHTML = ``;
            } else {
                statusEl.innerHTML = ``;
            }

            // Location mode presentation logic
            const isLoc = window.currentIsLocationMode;
            const controlsLeft = document.getElementById('inline-awb-add-controls-left');
            const controlsHeader = document.getElementById('inline-awb-add-header');
            const bottomSection = document.getElementById('awb-bottom-section');
            
            toggleLocReadonlyState(window.locModalReadonly);
            
            if (isLoc) {
                if (controlsLeft) controlsLeft.style.display = 'none';
                if (controlsHeader) controlsHeader.style.display = 'none';
                if (bottomSection) bottomSection.style.display = 'none';
                
                const specContainer = document.getElementById('inline-loc-specifics-container');
                if (specContainer) specContainer.style.display = 'flex';
                window.renderSpecificLocations();
            } else {
                if (controlsLeft) controlsLeft.style.display = 'flex';
                if (controlsHeader) controlsHeader.style.display = 'flex';
                if (bottomSection) bottomSection.style.display = 'block';
                
                document.querySelectorAll('.loc-pill').forEach(pill => {
                    pill.style.display = 'inline-block';
                    pill.style.pointerEvents = window.awbModalReadonly ? 'none' : 'auto';
                });

                const specContainer = document.getElementById('inline-loc-specifics-container');
                if (specContainer) specContainer.style.display = 'none';
                const emptyRack = document.getElementById('loc-default-rack');
                if (emptyRack) emptyRack.style.display = 'none';

                toggleReadonlyState(window.awbModalReadonly); // Re-enforce normal view display for buttons
            }

            window.renderLocalAwbItems();

            document.getElementById('inline-awb-modal-title').textContent = `AWB: ${num}`;
            document.getElementById('inline-awb-modal-pcs').textContent = pcs || '0';
            document.getElementById('inline-awb-modal-tot').textContent = tot || '0';
            document.getElementById('inline-awb-modal-wgt').textContent = wgt ? `${wgt} kg` : '0 kg';
            
            const hseArray = hse ? String(hse).split(',').map(s=>s.trim()).filter(Boolean) : [];
            const hseCount = hseArray.length;
            const hsesEl = document.getElementById('inline-awb-modal-hses');
            if (hsesEl) {
                if (hseCount > 0) {
                    const escapedHse = String(hse).replace(/'/g, "\\'").replace(/"/g, '&quot;');
                    hsesEl.innerHTML = `<span style="background:#e0e7ff; color:#4f46e5; padding:2px 8px; border-radius:10px; font-size:12px; font-weight:700; cursor:pointer; display:inline-block;" onclick="window.showHouseNumbersModal('${escapedHse}')" title="Click to view all">${hseCount}</span>`;
                } else {
                    hsesEl.innerHTML = `<span style="color:#94a3b8; font-size:12px; font-weight:700;">0</span>`;
                }
            }
            
            const remEl = document.getElementById('inline-awb-modal-rem-full');
            if(remEl) remEl.textContent = rem || 'No notes provided.';

            const discContainer = document.getElementById('inline-awb-modal-disc-container');
            const discFull = document.getElementById('inline-awb-modal-disc-full');
            let mismatchText = null;
            if (window.currentAwbParsed && window.currentAwbParsed['Mismatch Report']) {
                mismatchText = window.currentAwbParsed['Mismatch Report'].trim();
            }
            if (discContainer && discFull) {
                if (mismatchText && mismatchText.length > 0) {
                    discContainer.style.display = 'flex';
                    let formattedMismatch = mismatchText;
                    const match = mismatchText.match(/([0-9]+)\s*piece\(s\)\s*(SHORT|OVER)/i);
                    if (match) {
                        formattedMismatch = `${match[1]} ${match[2].toUpperCase()}`;
                    }
                    discFull.textContent = formattedMismatch;
                } else {
                    discContainer.style.display = 'none';
                    discFull.textContent = '-';
                }
            }

            if(typeof window.switchAwbModalTab === 'function') {
                window.switchAwbModalTab('data');
            }
            
            document.getElementById('inline-awb-modal-overlay').classList.add('open');
            document.getElementById('inline-awb-modal').classList.add('open');
        };

        window.enableAwbEditMode = function() {
            window.awbModalReadonly = false;
            
            ['agi', 'pre', 'crate', 'box', 'other'].forEach(id => {
                const el = document.getElementById('inline-awb-input-' + id);
                if(el) el.readOnly = false;
            });
            const otherInput = document.getElementById('inline-awb-loc-other-input');
            if (otherInput) otherInput.readOnly = false;

            document.querySelectorAll('.loc-pill').forEach(pill => {
                pill.style.pointerEvents = 'auto';
            });

            const svBtn = document.getElementById('inline-awb-save-btn');
            const edBtn = document.getElementById('inline-awb-edit-btn');
            if (svBtn) svBtn.style.display = 'block';
            if (edBtn) edBtn.style.display = 'none';

            const statusEl = document.getElementById('inline-awb-status-banner');
            if (statusEl) {
                statusEl.innerHTML = `<div style="width: 100%; text-align: center; background: #fef9c3; color: #854d0e; font-size: 11px; font-weight: 700; padding: 6px; letter-spacing: 0.5px; border-bottom: 1px solid #fde047; text-transform: uppercase;"><i class="fas fa-pencil-alt" style="margin-right:4px;"></i> Edit Mode Active</div>`;
            }

            window.renderLocalAwbItems();
        };

        window.enableLocEditMode = function() {
            window.locModalReadonly = false;
            
            const locCompleteBtn = document.getElementById('inline-awb-loc-complete-btn');
            const locEditBtn = document.getElementById('inline-awb-loc-edit-btn');
            
            if (locCompleteBtn) locCompleteBtn.style.display = 'block';
            if (locEditBtn) locEditBtn.style.display = 'none';
            
            const statusEl = document.getElementById('inline-awb-status-banner');
            if (statusEl) {
                statusEl.innerHTML = `<div style="width: 100%; text-align: center; background: #fef9c3; color: #854d0e; font-size: 11px; font-weight: 700; padding: 6px; letter-spacing: 0.5px; border-bottom: 1px solid #fde047; text-transform: uppercase;"><i class="fas fa-pencil-alt" style="margin-right:4px;"></i> Location Edit Mode Active</div>`;
            }

            window.renderLocalAwbItems();
        };
        window.updateTableCounters = function(tableBodyId) {
            const tbody = document.getElementById(tableBodyId);
            if (!tbody) return;
            let counterDiv;
            if (tableBodyId === 'sys-ulds-left') counterDiv = document.getElementById('sys-counter-left');
            else if (tableBodyId === 'sys-ulds-right') counterDiv = document.getElementById('sys-counter-right');
            else if (tableBodyId === 'coord-ulds') counterDiv = document.getElementById('coord-counter');
            
            if (!counterDiv) return;

            let total = 0, totalBreak = 0, totalNoBreak = 0;
            let checkedTotal = 0, checkedBreak = 0, checkedNoBreak = 0;

            const rows = tbody.querySelectorAll('tr[data-bg]');
            rows.forEach(row => {
                total++;
                const isUldBreak = row.getAttribute('data-is-break') === 'true';
                
                if (isUldBreak) totalBreak++;
                else totalNoBreak++;

                let isUldChecked = false;
                if (tableBodyId.includes('sys-ulds')) {
                    const cb = row.querySelector('.sys-uld-checkbox');
                    if (cb && cb.checked) isUldChecked = true;
                } else if (tableBodyId === 'coord-ulds') {
                    const btn = row.querySelector('.coord-uld-check-btn');
                    if (btn) {
                        const status = btn.getAttribute('data-status') || '';
                        if (status === 'Checked' || status === 'Ready') isUldChecked = true;
                    }
                }

                if (isUldChecked) {
                    checkedTotal++;
                    if (isUldBreak) checkedBreak++;
                    else checkedNoBreak++;
                }
            });

            if (total === 0) {
                counterDiv.innerHTML = '';
                return;
            }

            counterDiv.innerHTML = `
                <div style="display:flex; gap:12px; font-size: 13px;">
                    <div title="Break ULDs"><span style="color:#94a3b8;">Break:</span> <strong style="color:#166534;">${checkedBreak} / ${totalBreak}</strong></div>
                    <div title="No-Break ULDs"><span style="color:#94a3b8;">No-Break:</span> <strong style="color:#991b1b;">${checkedNoBreak} / ${totalNoBreak}</strong></div>
                    <div title="Total ULDs"><span style="color:#94a3b8;">Total:</span> <strong style="color:#475569;">${checkedTotal} / ${total}</strong></div>
                </div>
            `;
        };

        window.markUldAsChecked = async function(uldId, uldNumber, btn, isLocView = false, flightId = null) {
            const originalHtml = btn.innerHTML;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
            btn.disabled = true;
            
            const targetStatus = isLocView ? 'Ready' : 'Checked';
            
            try {
                const { error } = await supabaseClient.from('ULD').update({status: targetStatus}).eq('id', uldId);
                if (error) throw error;
                btn.innerHTML = isLocView ? '<i class="fas fa-check" style="margin-right:4px;"></i> SAVED' : '<i class="fas fa-check" style="margin-right:4px;"></i> CHECKED';
                btn.style.background = '#10b981';
                btn.style.color = 'white';
                btn.style.cursor = 'default';
                btn.setAttribute('data-status', targetStatus);

                if (btn.closest('tbody')) {
                    const tId = btn.closest('tbody').id;
                    if (window.updateTableCounters) window.updateTableCounters(tId);
                }

                if (!isLocView && flightId) {
                    const { data: fData, error: fErr } = await supabaseClient.from('Flight').select('*').eq('id', flightId).single();
                    if (!fErr && fData) {
                        // Create a precise string for Chicago Time (YYYY-MM-DDTHH:mm:ss) 
                        // so Supabase saves the literal local timestamp without UTC shifts.
                        const formatter = new Intl.DateTimeFormat('en-US', {
                            timeZone: 'America/Chicago',
                            year: 'numeric', month: '2-digit', day: '2-digit',
                            hour: '2-digit', minute: '2-digit', second: '2-digit',
                            hour12: false
                        });
                        const p = {};
                        formatter.formatToParts(new Date()).forEach(part => p[part.type] = part.value);
                        const h = p.hour === '24' ? '00' : p.hour;
                        const nowChicagoIso = `${p.year}-${p.month}-${p.day}T${h}:${p.minute}:${p.second}`;

                        let updates = {};

                        // Only assign start-break if it's completely empty.
                        const isStartEmpty = (!fData['start-break'] || String(fData['start-break']).trim() === '' || fData['start-break'] === '-');
                        if (isStartEmpty) {
                            updates['start-break'] = nowChicagoIso;
                        }

                         if (Object.keys(updates).length > 0) {
                            await supabaseClient.from('Flight').update(updates).eq('id', flightId);
                            if (window.fetchFlights) {
                                window.fetchFlights();
                            }
                        }
                    }
                }

                // Immediately re-evaluate the coordinator flight check button if we're in coordinator view
                const coordTbody = document.getElementById('coord-ulds');
                if (coordTbody && coordTbody.contains(btn)) {
                    window.checkFlightReadyStatus();
                }
                const locTbody = document.getElementById('loc-ulds');
                if (locTbody && locTbody.contains(btn) && window.checkLocFlightReadyStatus) {
                    window.checkLocFlightReadyStatus();
                }

            } catch (err) {
                console.error(err);
                alert("Failed to update ULD status.");
                btn.innerHTML = originalHtml;
                btn.disabled = false;
            }
        };

        window.saveCoordinatorData = async function(btn, overrideMismatch = false) {
            if (!window.currentAwbEditing || !window.currentAwbEditing.id) return;
            
            const originalText = btn ? btn.innerHTML : 'Save';
            if (btn) {
                btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
                btn.disabled = true;
            }

            try {
                // Get authenticated user for coordinator info
                const { data: { session } } = await supabaseClient.auth.getSession();
                let userName = session?.user?.user_metadata?.name || session?.user?.email || 'Unknown User';
                if (session?.user?.id) {
                    try {
                        const { data: uData } = await supabaseClient.from('Users').select('full-name').eq('ref-ID', session.user.id).single();
                        if (uData && uData['full-name']) userName = uData['full-name'];
                    } catch(e){}
                }
                const checkTime = new Date().toISOString();
                // Determine location Selected
                let locVal = '';
                const selectedPill = document.querySelector('.loc-pill.selected');
                if (selectedPill) {
                    if (selectedPill.textContent.trim().toLowerCase() === 'other') {
                        locVal = document.getElementById('inline-awb-loc-other-input').value.trim();
                    } else {
                        locVal = selectedPill.textContent.trim();
                    }
                }

                const totalEl = document.getElementById('inline-awb-total-checked');
                const totalChecked = totalEl ? parseInt(totalEl.innerText, 10) || 0 : 0;

                const mismatchEl = document.getElementById('awb-mismatch-report');
                let reportValue = mismatchEl ? mismatchEl.value.trim() : "";
                const expectedPcs = window.currentAwbEditing.pcs || 0;
                const hasMismatch = window.currentAwbEditing.pcs !== undefined && totalChecked !== expectedPcs;

                // Mismatch Overlay Check
                if (!overrideMismatch && hasMismatch) {
                    const overlay = document.getElementById('mismatch-overlay-modal');
                    if (overlay) {
                        const titleEl = document.getElementById('mismatch-modal-title');
                        const descEl = document.getElementById('mismatch-modal-desc');
                        
                        const diff = Math.abs(totalChecked - expectedPcs);
                        const isShort = totalChecked < expectedPcs;
                        
                        const typeStr = isShort ? 'SHORT' : 'OVER';
                        const iconColor = isShort ? '#f97316' : '#8b5cf6'; // Orange for short, Purple for over
                        
                        titleEl.innerHTML = `<i class="fas fa-exclamation-circle" style="margin-right:8px; color:${iconColor};"></i> <span style="color:${iconColor};">Pieces Discrepancy (${typeStr})</span>`;
                        descEl.innerHTML = `You have checked <b>${totalChecked}</b> pieces out of <b>${expectedPcs}</b> expected.<br><br>There is a discrepancy of <b>${diff} pieces ${typeStr}</b>.<br><br>Do you confirm that there are ${diff} pieces ${typeStr}?`;
                        
                        const overlayRep = document.getElementById('awb-mismatch-overlay-report');
                        if (overlayRep) {
                            overlayRep.value = `AWB ${window.currentAwbEditing.num}: ${diff} piece(s) ${typeStr}`; // preset the exact report generated
                        }
                        
                        overlay.style.display = 'flex';
                        
                        if(btn) {
                            btn.innerHTML = 'Save';
                            btn.disabled = false;
                        }
                        return; // Halt saving process until they confirm
                    }
                }

                // If executing here, we either matched, or the user confirmed the overlay popup
                if (overrideMismatch) {
                    const overlayRep = document.getElementById('awb-mismatch-overlay-report');
                    if (overlayRep) reportValue = overlayRep.value.trim();
                } else {
                    // if it matched, but they previously had a mismatch report, clear it
                    reportValue = "";
                }

                const newEntry = {
                    awbNumber: window.currentAwbEditing.num,
                    refCarrier: window.currentAwbEditing.refCarrier,
                    refNumber: window.currentAwbEditing.refNumber,
                    refDate: window.currentAwbEditing.refDate,
                    refULD: window.currentAwbEditing.refULD,
                    "Agi skid": currentLocalAwbItems.agi.map(a => a.qty),
                    "Pre skid": currentLocalAwbItems.pre.map(a => a.qty),
                    "Crates": currentLocalAwbItems.crate.map(a => a.qty),
                    "Box": currentLocalAwbItems.box.map(a => a.qty),
                    "Other": currentLocalAwbItems.other.map(a => a.qty),
                    "Location required": locVal,
                    "Total Checked": totalChecked,
                    "Mismatch Report": reportValue,
                    "itemLocations": window.currentAwbParsed ? window.currentAwbParsed.itemLocations || {} : {},
                    "specificLocations": window.currentAwbParsed ? window.currentAwbParsed.specificLocations || [] : [],
                    "checkedBy": userName,
                    "checkedAt": checkTime
                };

                // Fetch current list
                const { data, error } = await supabaseClient
                    .from('AWB')
                    .select('"data-coordinator"')
                    .eq('id', window.currentAwbEditing.id)
                    .single();
                
                if (error) throw error;
                
                let coordList = data['data-coordinator'];
                if (!Array.isArray(coordList)) {
                    try {
                        coordList = JSON.parse(coordList);
                        if (!Array.isArray(coordList)) coordList = [];
                    } catch(e) {
                        coordList = [];
                    }
                }

                // Check if an entry for this ULD flight context already exists
                const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();

                const existingIndex = coordList.findIndex(c => 
                    eqRef(c.refCarrier, window.currentAwbEditing.refCarrier) &&
                    eqRef(c.refNumber, window.currentAwbEditing.refNumber) &&
                    eqRef(c.refDate, window.currentAwbEditing.refDate) &&
                    eqRef(c.refULD, window.currentAwbEditing.refULD)
                );

                if (existingIndex > -1) {
                    coordList[existingIndex] = newEntry; // Override
                } else {
                    coordList.push(newEntry); // Add new
                }

                // Update row
                const { error: updateError } = await supabaseClient
                    .from('AWB')
                    .update({ 'data-coordinator': coordList })
                    .eq('id', window.currentAwbEditing.id);

                if (updateError) throw updateError;
                
                // Close modal on success
                document.getElementById('inline-awb-modal').classList.remove('open');
                document.getElementById('inline-awb-modal-overlay').classList.remove('open');
                
                // Auto-refresh the currently open ULD row to reflect the new checkmark
                const openInlines = document.querySelectorAll('.inline-details-row');
                if (openInlines.length > 0) {
                    const parentTr = openInlines[0].previousElementSibling;
                    if (parentTr) {
                        parentTr.click(); // Close
                        setTimeout(() => parentTr.click(), 50); // Re-open
                    }
                }

                if (typeof window.fetchGlobalAwbs === 'function') {
                    window.fetchGlobalAwbs();
                }
                
                if (window.currentSelectedFlightForReports) {
                    window.refreshFlightDiscrepancies(window.currentSelectedFlightForReports);
                }

            } catch (err) {
                console.error("Error saving coordinator data:", err);
                alert("Failed to save data. Try again.");
            } finally {
                btn.innerHTML = originalText;
                btn.disabled = false;
            }
        };

        window.openAwbPanelReadOnly = async function(uldParam) {
            currentUldIdForAwb = null; // Prevent modification properties for Add Flight/Local
            const footer = document.getElementById('awb-drawer-footer');
            if (footer) footer.style.display = 'none';

            let uld = null;
            if (typeof uldParam === 'object' && uldParam !== null) {
                uld = uldParam;
            } else {
                uld = localUlds.find(u => u.id == uldParam || u["ULD number"] == uldParam || u.uld_number == uldParam);
            }
            if(!uld) return;

            currentReadOnlyUldId = uld.id; // Guarda la ID para posible edit directo en base de datos

            const uNumber = uld["ULD number"] || uld.uld_number || uld.id;
            drawerUldTitle.textContent = `ULD: ${uNumber}`;
            
            if (drawerUldFlightRef) {
                if (uld.refCarrier || uld.refNumber) {
                    const carrier = uld.refCarrier || '';
                    const number = uld.refNumber || '';
                    const date = uld.refDate ? new Date(uld.refDate + 'T12:00:00').toLocaleDateString() : '';
                    drawerUldFlightRef.textContent = `Flight: ${carrier} ${number} ${date}`.trim();
                    drawerUldFlightRef.style.color = '#4f46e5'; // Blue
                    drawerUldFlightRef.style.display = 'block';
                } else {
                    drawerUldFlightRef.textContent = 'No Flight';
                    drawerUldFlightRef.style.color = '#ef4444'; // Red
                    drawerUldFlightRef.style.display = 'block';
                }
            }
            
            if(drawerUldPcs) drawerUldPcs.textContent = uld.pieces || '0';
            if(drawerUldWgt) drawerUldWgt.textContent = (uld.weight || '0') + ' kg';
            
            const isPrio = uld.isPriority || uld.priority;
            const isBrk = uld.isBreak || uld.break;
            let cStatus = (uld.status || uld.Status || 'received').toLowerCase();
            
            if(drawerUldPrio) drawerUldPrio.textContent = isPrio ? 'Yes' : 'No';
            if(drawerUldBrk) drawerUldBrk.textContent = isBrk ? 'Break' : 'No Break';
            if(drawerUldSts) drawerUldSts.innerHTML = window.getULDStatusBadgeHtml(cStatus);
            if(drawerUldRem) drawerUldRem.textContent = uld.remarks || 'N/A';

            const uldEditModeSwitch = document.getElementById('uld-edit-mode-switch');
            if (uldEditModeSwitch) {
                uldEditModeSwitch.checked = false;
                uldEditModeSwitch.dispatchEvent(new Event('change'));
            }

            // Loading state
            if (drawerAwbTable) {
                drawerAwbTable.innerHTML = '<tr><td colspan="8" style="padding: 16px; text-align: center; color: #94a3b8; font-size: 12px; font-style: italic;">Fetching AWBs from database...</td></tr>';
            }
            
            // Abrir Drawer Animado (inmediatamente para percibir la carga)
            awbDrawer.classList.add('open');
            awbOverlay.classList.add('open');

            // Fetch from Supabase
            try {
                const { data: awbs, error } = await supabaseClient.from('AWB').select('*');
                let matchedAwbs = [];
                if (!error && awbs) {
                    awbs.forEach(awbDoc => {
                        let nestedArr = [];
                        if (Array.isArray(awbDoc['data-AWB'])) {
                            nestedArr = awbDoc['data-AWB'];
                        } else if (awbDoc['data-AWB']) {
                            try { nestedArr = JSON.parse(awbDoc['data-AWB']); } catch(e){}
                        }

                        if (nestedArr.length > 0) {
                            const nestedData = nestedArr.find(n => {
                                const nUld = String(n.refULD || '').trim().toLowerCase();
                                const nCarrier = String(n.refCarrier || '').trim().toLowerCase();
                                const nNumber = String(n.refNumber || '').replace(/^0+/, '').trim().toLowerCase();
                                const nDate = String(n.refDate || '').trim().toLowerCase();
                                
                                const tUld = String(uNumber || '').trim().toLowerCase();
                                const tCarrier = String(uld.refCarrier || '').trim().toLowerCase();
                                const tNumber = String(uld.refNumber || '').replace(/^0+/, '').trim().toLowerCase();
                                const tDate = String(uld.refDate || '').trim().toLowerCase();
                                
                                const sameDate = (nDate === tDate || (nDate && tDate.includes(nDate)) || (tDate && nDate.includes(tDate)) || !tDate);
                                
                                return nUld === tUld &&
                                       (!tCarrier || nCarrier === tCarrier) &&
                                       (!tNumber || nNumber === tNumber) &&
                                       sameDate;
                            });
                            if (nestedData) {
                                matchedAwbs.push({
                                    awb_number: awbDoc['AWB number'] || awbDoc.awb_number || 'Unknown AWB',
                                    pieces: nestedData.pieces || 0,
                                    weight: nestedData.weight || 0,
                                    total: awbDoc.total,
                                    house_number: nestedData.houses || nestedData.house_number || [],
                                    remarks: nestedData.remarks || '-'
                                });
                            }
                        }
                    });
                }

                if (drawerAwbTable) {
                    drawerAwbTable.innerHTML = '';
                    if (matchedAwbs.length === 0) {
                        drawerAwbTable.innerHTML = '<tr><td colspan="8" style="padding: 16px; text-align: center; color: #94a3b8; font-size: 12px; font-style: italic;">No AWBs associated with this ULD.</td></tr>';
                    } else {
                        matchedAwbs.forEach((awb, index) => {
                            const tr = document.createElement('tr');
                            const hList = awb.house_number || [];
                            const hCount = hList.length;
                            const safeHStr = hList.join(',').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                            const hBadge = hCount > 0 
                                           ? `<span style="background:#e0e7ff; color:#4f46e5; padding:2px 6px; border-radius:10px; font-size:9px; cursor:pointer;" onclick="window.showHouseNumbersModal('${safeHStr}')" title="Click to view all">${hCount}</span>` 
                                           : `<span style="color:#94a3b8; font-size:10px;">0</span>`;

                            tr.innerHTML = `
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; font-weight: 500; text-align: center;">
                                    ${index + 1}
                                </td>
                                <td style="padding: 12px; font-size: 11px; color: #334155; border-bottom: 1px solid #f1f5f9; font-weight: 500; white-space: nowrap;">
                                    ${awb.awb_number}
                                </td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${awb.pieces}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${awb.total || '0'}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${awb.weight}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${hBadge}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; width: 100%; max-width: 0;">
                                    <span style="display:block; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; width:100%;" title="${awb.remarks || ''}">${awb.remarks || '-'}</span>
                                </td>
                                <td style="padding: 12px; font-size: 11px; border-bottom: 1px solid #f1f5f9; text-align: right;">
                                    <span style="color:#cbd5e1; font-size: 10px;">-</span>
                                </td>
                            `;
                            drawerAwbTable.appendChild(tr);
                        });
                    }
                }
            } catch (err) {
                console.error("Error fetching AWBs read-only:", err);
                if (drawerAwbTable) {
                    drawerAwbTable.innerHTML = '<tr><td colspan="8" style="padding: 16px; text-align: center; color: #ef4444; font-size: 12px;">Failed to load AWBs.</td></tr>';
                }
            }
        };

        window.openCoordAwbDrawer = async function(uld, flight) {
            currentUldIdForAwb = null; 
            const footer = document.getElementById('awb-drawer-footer');
            if (footer) footer.style.display = 'none';

            const uNumber = uld["ULD number"] || uld.uld_number || uld.id || 'N/A';
            drawerUldTitle.textContent = `ULD: ${uNumber}`;
            
            if (drawerUldFlightRef) {
                if (flight) {
                    const carrier = flight.carrier || '';
                    const number = flight.number || '';
                    const dateObj = flight['date-arrived'];
                    const date = dateObj ? new Date(dateObj + 'T12:00:00').toLocaleDateString() : '';
                    drawerUldFlightRef.textContent = `Flight: ${carrier} ${number} ${date}`.trim();
                    drawerUldFlightRef.style.color = '#4f46e5'; // Blue
                    drawerUldFlightRef.style.display = 'block';
                } else {
                    drawerUldFlightRef.textContent = 'No Flight';
                    drawerUldFlightRef.style.color = '#ef4444'; // Red
                    drawerUldFlightRef.style.display = 'block';
                }
            }
            
            if(drawerUldPcs) drawerUldPcs.textContent = uld.pieces || '0';
            if(drawerUldWgt) drawerUldWgt.textContent = (uld.weight || '0') + ' kg';
            
            const isPrio = uld.isPriority || uld.priority;
            const isBrk = uld.isBreak || uld.break;
            if(drawerUldPrio) drawerUldPrio.innerHTML = isPrio ? '<span style="color:#ef4444; font-weight:600;">Yes</span>' : 'No';
            if(drawerUldBrk) drawerUldBrk.innerHTML = isBrk ? '<span style="color:#4f46e5; font-weight:600;">Yes</span>' : 'No';
            if(drawerUldRem) drawerUldRem.textContent = uld.remarks || 'N/A';

            if (drawerAwbTable) {
                drawerAwbTable.innerHTML = '<tr><td colspan="8" style="padding: 16px; text-align: center; color: #94a3b8; font-size: 12px; font-style: italic;">Fetching AWBs from database...</td></tr>';
            }
            
            awbDrawer.classList.add('open');
            awbOverlay.classList.add('open');

            try {
                const fCarrier = flight.carrier || '';
                const fNumber = flight.number || '';
                const fDate = flight['date-arrived'];
                const refDate = fDate ? new Date(fDate + 'T12:00:00').toLocaleDateString() : '';
                const strictFlightRefString = `${fCarrier} ${fNumber} ${refDate}`.trim();
                const partialFlightRef = `${fCarrier} ${fNumber}`.trim();
                
                const officialDayStr = fDate ? parseInt(fDate.split('-')[2], 10).toString() : ''; 
                const officialMonthStr = fDate ? parseInt(fDate.split('-')[1], 10).toString() : '';
                const tzDay = fDate ? new Date(fDate).getDate().toString() : '';

                const { data: awbs, error } = await supabaseClient.from('AWB').select('*');
                let matchedAwbs = [];
                if (!error && awbs) {
                    awbs.forEach(awbDoc => {
                        if (awbDoc['data-AWB'] && Array.isArray(awbDoc['data-AWB'])) {
                            const nestedDatas = awbDoc['data-AWB'].filter(n => {
                                const nUld = String(n.refULD || '').trim().toLowerCase();
                                const tUld = String(uNumber || '').trim().toLowerCase();
                                if (nUld !== tUld) return false;
                                
                                const nCarrier = String(n.refCarrier || '').trim().toLowerCase();
                                const nNumber = String(n.refNumber || '').replace(/^0+/, '').trim().toLowerCase();
                                const nDate = String(n.refDate || '').trim().toLowerCase();
                                
                                const tCarrier = String(fCarrier || '').trim().toLowerCase();
                                const tNumber = String(fNumber || '').replace(/^0+/, '').trim().toLowerCase();
                                const tDate = String(refDate || '').trim().toLowerCase();
                                
                                if (nCarrier || nNumber) {
                                    const sameDate = (nDate === tDate || (nDate && tDate.includes(nDate)) || (tDate && nDate.includes(tDate)) || !tDate);
                                    return (!tCarrier || nCarrier === tCarrier) && (!tNumber || nNumber === tNumber) && sameDate;
                                } else if (n.refFlight) {
                                    const nFlight = String(n.refFlight || '').trim().toLowerCase();
                                    const strictF = String(strictFlightRefString || '').trim().toLowerCase();
                                    const partialF = String(partialFlightRef || '').trim().toLowerCase();
                                    
                                    if (nFlight === strictF || nFlight.includes(partialF)) return true;
                                }
                                
                                return false;
                            });

                            nestedDatas.forEach(nestedData => {
                                matchedAwbs.push({
                                    awb_number: awbDoc['AWB number'] || awbDoc.awb_number,
                                    pieces: nestedData.pieces || 0,
                                    weight: nestedData.weight || 0,
                                    total: awbDoc.total,
                                    house_number: nestedData.houses || nestedData.house_number || [],
                                    remarks: nestedData.remarks || '-',
                                    matched_flight_ref: nestedData.refCarrier ? `${nestedData.refCarrier} ${nestedData.refNumber} ${nestedData.refDate}` : nestedData.refFlight
                                });
                            });
                        }
                    });
                }

                if (drawerAwbTable) {
                    drawerAwbTable.innerHTML = '';
                    if (matchedAwbs.length === 0) {
                        drawerAwbTable.innerHTML = '<tr><td colspan="8" style="padding: 16px; text-align: center; color: #94a3b8; font-size: 12px; font-style: italic;">No AWBs associated with this ULD on this flight.</td></tr>';
                    } else {
                        matchedAwbs.forEach((awb, index) => {
                            const tr = document.createElement('tr');
                            const hList = awb.house_number || [];
                            const hCount = hList.length;
                            const safeHStr = hList.join(',').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                            const hBadge = hCount > 0 
                                           ? `<span style="background:#e0e7ff; color:#4f46e5; padding:2px 6px; border-radius:10px; font-size:9px; cursor:pointer;" onclick="window.showHouseNumbersModal('${safeHStr}')" title="Click to view all">${hCount}</span>` 
                                           : `<span style="color:#94a3b8; font-size:10px;">0</span>`;

                            tr.style.cursor = 'pointer';
                            tr.style.transition = 'all 0.2s';
                            tr.onmouseover = () => { tr.style.background = '#f8fafc'; };
                            tr.onmouseout = () => { tr.style.background = 'transparent'; };
                            
                            tr.addEventListener('click', () => {
                                window.openReceiveModal(awb, awb.matched_flight_ref || strictFlightRefString, uNumber);
                            });

                            tr.innerHTML = `
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; font-weight: 500; text-align: center;">
                                    ${index + 1}
                                </td>
                                <td style="padding: 12px; font-size: 11px; color: #334155; border-bottom: 1px solid #f1f5f9; font-weight: 500; white-space: nowrap;">
                                    ${awb.awb_number}
                                </td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${awb.pieces}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${awb.total || '0'}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${awb.weight} kg</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; text-align: center;">${hBadge}</td>
                                <td style="padding: 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; width: 100%; max-width: 0;">
                                    <span style="display:block; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; width:100%;" title="${awb.remarks || ''}">${awb.remarks || '-'}</span>
                                </td>
                                <td style="padding: 12px; font-size: 11px; border-bottom: 1px solid #f1f5f9; text-align: right;">
                                    <span style="color:#cbd5e1; font-size: 10px;">-</span>
                                </td>
                            `;
                            drawerAwbTable.appendChild(tr);
                        });
                    }
                }
            } catch (err) {
                console.error("Error fetching AWBs coord:", err);
                if (drawerAwbTable) {
                    drawerAwbTable.innerHTML = '<tr><td colspan="8" style="padding: 16px; text-align: center; color: #ef4444; font-size: 12px;">Failed to load AWBs.</td></tr>';
                }
            }
        };

        // --- RECEIVE MODAL LOGIC ----
        const recModalOverlay = document.getElementById('awb-receive-modal-overlay');
        const closeRecModalBtn = document.getElementById('close-receive-modal-btn');
        const cancelRecBtn = document.getElementById('cancel-receive-btn');
        const saveRecBtn = document.getElementById('save-receive-btn');
        
        // Input y display fields
        let currentReceivedAwbContext = null;

        // Required Location Choice Logic
        const reqLocOtherWrapper = document.getElementById('req-loc-other-wrapper');
        const reqLocOtherInput = document.getElementById('req-loc-other-input');
        
        // Listen to all radio buttons in loc-chip directly:
        document.addEventListener('change', (e) => {
            if (e.target.name === 'rec-location') {
                if (e.target.value === 'Other') {
                    if (reqLocOtherWrapper) reqLocOtherWrapper.style.display = 'block';
                    if (reqLocOtherInput) reqLocOtherInput.focus();
                } else {
                    if (reqLocOtherWrapper) reqLocOtherWrapper.style.display = 'none';
                    if (reqLocOtherInput) reqLocOtherInput.value = '';
                }
            }
        });

        // Function to compute total pieces dynamically
        function updateTotalPiecesChecked() {
            let total = 0;
            // Sum list items logic
            ['AGI Skid', 'Pre Skid', 'Crate', 'Box', 'Other'].forEach(t => {
                if (packageState[t]) {
                    total += packageState[t].reduce((acc, curr) => acc + curr, 0);
                }
            });
            
            const totalPcsEl = document.getElementById('rec-inp-pcs');
            if (totalPcsEl) {
                 totalPcsEl.textContent = total;
            }
        }

        // Package Lists Setup
        const packageTypesConfig = [
            { id: 'agi-skid', name: 'AGI Skid' },
            { id: 'pre-skid', name: 'Pre Skid' },
            { id: 'crate', name: 'Crate' },
            { id: 'box', name: 'Box' },
            { id: 'other', name: 'Other' }
        ];

        const packageState = {
            'AGI Skid': [],
            'Pre Skid': [],
            'Crate': [],
            'Box': [],
            'Other': []
        };

        function renderPackageList(typeId, typeName) {
            const listEl = document.getElementById(`${typeId}-list`);
            if (!listEl) return;
            listEl.innerHTML = '';
            
            const isAgi = typeName === 'AGI Skid';

            packageState[typeName].forEach((qty, idx) => {
                const chip = document.createElement('div');
                chip.style.cssText = 'display: flex; justify-content: space-between; align-items: center; width: 100%; padding: 6px 10px; background: transparent; border-radius: 6px; font-size: 14px; color: #64748b; box-sizing: border-box;';
                
                let numBadge = '';
                if(isAgi) {
                    numBadge = `<div style="width: 20px; height: 20px; border-radius: 50%; border: 1px solid #4f46e5; color: #4f46e5; display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: 700;">${idx + 1}</div>`;
                }

                chip.innerHTML = `
                    <div style="display: flex; align-items: center; gap: 12px;">
                        ${numBadge}
                        <span style="font-weight: 600; color: #0f172a;">${qty}</span>
                    </div>
                    <button class="del-pkg-btn" data-type="${typeName}" data-idx="${idx}" style="background: transparent; border: none; color: #94a3b8; font-size: 15px; cursor: pointer; padding: 0; display: flex; align-items: center;">✕</button>
                `;
                listEl.appendChild(chip);
            });

            listEl.querySelectorAll('.del-pkg-btn').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const tName = e.currentTarget.getAttribute('data-type');
                    const idx = parseInt(e.currentTarget.getAttribute('data-idx'));
                    packageState[tName].splice(idx, 1);
                    renderPackageList(typeId, tName);
                    updateTotalPiecesChecked();
                });
            });
        }

        packageTypesConfig.forEach(config => {
            const inputEl = document.getElementById(`${config.id}-input`);
            const btnEl = document.getElementById(`add-${config.id}-btn`);
            
            if (btnEl && inputEl) {
                btnEl.addEventListener('click', () => {
                    const val = parseInt(inputEl.value);
                    if (!isNaN(val) && val > 0) {
                        packageState[config.name].push(val);
                        inputEl.value = '';
                        renderPackageList(config.id, config.name);
                        updateTotalPiecesChecked();
                    }
                });

                inputEl.addEventListener('keyup', (e) => {
                    if (e.key === 'Enter') btnEl.click();
                });
            }
        });

        window.openReceiveModal = function(awbData, flightRef, uldRef) {
            currentReceivedAwbContext = { awbData, flightRef, uldRef };
            
            document.getElementById('receive-modal-title').textContent = awbData.awb_number || 'AWB number';
            document.getElementById('rec-exp-pcs').textContent = awbData.pieces || '0';
            document.getElementById('rec-exp-wgt').textContent = awbData.weight || '0';
            document.getElementById('rec-exp-wgt').textContent = awbData.weight || '0';
            
            // Set Initial Display for textContent Div replacing value Input
            document.getElementById('rec-inp-pcs').textContent = '0';
            
            // Reset Package Lists
            packageTypesConfig.forEach(config => {
                packageState[config.name] = [];
                const inputEl = document.getElementById(`${config.id}-input`);
                if(inputEl) inputEl.value = '';
                renderPackageList(config.id, config.name);
            });
            
            const reqIntact = document.querySelector('input[name="rec-condition"][value="Intact"]');
            if(reqIntact) reqIntact.checked = true;

            document.querySelectorAll('input[name="rec-location"]').forEach(input => input.checked = false);
            if (reqLocOtherWrapper) reqLocOtherWrapper.style.display = 'none';
            if (reqLocOtherInput) reqLocOtherInput.value = '';

            document.getElementById('rec-inp-notes').value = '';
            
            if(saveRecBtn) {
                saveRecBtn.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg> Save Record`;
                saveRecBtn.disabled = false;
                saveRecBtn.style.opacity = '1';
                saveRecBtn.style.cursor = 'pointer';
                saveRecBtn.style.background = '#4f46e5';
            }

            recModalOverlay.style.display = 'flex';
        };

        const closeRecModal = () => {
            recModalOverlay.style.display = 'none';
            currentReceivedAwbContext = null;
        };

        if (closeRecModalBtn) closeRecModalBtn.addEventListener('click', closeRecModal);
        if (cancelRecBtn) cancelRecBtn.addEventListener('click', closeRecModal);

        if (saveRecBtn) {
            saveRecBtn.addEventListener('click', async () => {
                if (!currentReceivedAwbContext) return;
                
                // Recolectar datos
                const totalPcsEl = document.getElementById('rec-inp-pcs');
                const totalPcs = totalPcsEl ? totalPcsEl.textContent : '0';

                if (!totalPcs || parseInt(totalPcs) <= 0) {
                    window.showValidationModal("Invalid Quantity", "Please enter a valid number of received pieces.");
                    return;
                }

                const composition = {};
                
                // Set Array items
                packageTypesConfig.forEach(config => {
                    if (packageState[config.name] && packageState[config.name].length > 0) {
                        composition[config.name] = [...packageState[config.name]];
                    }
                });

                const conditionNode = document.querySelector('input[name="rec-condition"]:checked');
                const condition = conditionNode ? conditionNode.value : 'Intact';
                
                const recLocNode = document.querySelector('input[name="rec-location"]:checked');
                let requiredLocation = '';
                if (recLocNode) {
                    if (recLocNode.value === 'Other') {
                        requiredLocation = document.getElementById('req-loc-other-input').value.trim();
                    } else {
                        requiredLocation = recLocNode.value;
                    }
                }

                const notes = document.getElementById('rec-inp-notes').value.trim();

                saveRecBtn.disabled = true;
                saveRecBtn.textContent = 'Saving...';
                saveRecBtn.style.opacity = '0.7';
                saveRecBtn.style.cursor = 'not-allowed';

                try {
                    const awbNum = currentReceivedAwbContext.awbData.awb_number;
                    const flightRef = currentReceivedAwbContext.flightRef;
                    const uldRef = currentReceivedAwbContext.uldRef;

                    // 1. Obtener el AWB original completo
                    const { data: currentAwbs, error: fetchErr } = await supabaseClient
                        .from('AWB')
                        .select('*')
                        .eq('AWB number', awbNum); 
                        
                    if (fetchErr || !currentAwbs || currentAwbs.length === 0) {
                        throw fetchErr || new Error("AWB not found");
                    }

                    const awbDoc = currentAwbs[0];
                    let nestedDataArray = awbDoc['data-AWB'];

                    // 2. Localizar y mutar el fragmento específico correspondiente
                    if (Array.isArray(nestedDataArray)) {
                        const splitIndex = nestedDataArray.findIndex(n => n.refULD === uldRef && n.refFlight === flightRef);
                        
                        if(splitIndex !== -1) {
                            nestedDataArray[splitIndex].received_data = {
                                received_pieces: parseInt(totalPcs),
                                composition: composition,
                                condition: condition,
                                required_location: requiredLocation,
                                remarks: notes,
                                receivedAt: new Date().toISOString()
                            };
                        }
                    }

                    // 3. Guardar el objeto entero de regreso a Supabase
                    const { error: updateErr } = await supabaseClient
                        .from('AWB')
                        .update({ 'data-AWB': nestedDataArray })
                        .eq('id', awbDoc.id);

                    if (updateErr) {
                        throw updateErr;
                    }

                    // Éxito:
                    saveRecBtn.textContent = 'Saved!';
                    saveRecBtn.style.background = '#10b981'; // Green
                    
                    setTimeout(() => {
                        closeRecModal();
                        saveRecBtn.style.background = '#4f46e5';
                    }, 800);

                } catch (err) {
                    console.error("Failed to save received data:", err);
                    alert("Error updating the database.");
                    saveRecBtn.innerHTML = `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path><polyline points="17 21 17 13 7 13 7 21"></polyline><polyline points="7 3 7 8 15 8"></polyline></svg> Save Record`;
                    saveRecBtn.disabled = false;
                    saveRecBtn.style.opacity = '1';
                    saveRecBtn.style.cursor = 'pointer';
                }
            });
        }
        // --- FIN RECEIVE MODAL ----

        // Cerrar panel
        function closeAwbPanel() {
            awbDrawer.classList.remove('open');
            awbOverlay.classList.remove('open');
            currentUldIdForAwb = null;
            currentReadOnlyUldId = null;
            renderLocalUlds(); // Quitar clase color de la fila si se cierra
            
            // Restaurar pie de página
            const footer = document.getElementById('awb-drawer-footer');
            if (footer) footer.style.display = 'block';

            // Resetear switch de modo edición al cerrar
            const uldEditModeSwitch = document.getElementById('uld-edit-mode-switch');
            if (uldEditModeSwitch && uldEditModeSwitch.checked) {
                uldEditModeSwitch.checked = false;
                uldEditModeSwitch.dispatchEvent(new Event('change'));
            }
        }

        if(closeDrawerBtn) closeDrawerBtn.addEventListener('click', closeAwbPanel);
        if(awbOverlay) awbOverlay.addEventListener('click', closeAwbPanel);

        // Edit Mode Switch for ULD Drawer
        const uldEditModeSwitch = document.getElementById('uld-edit-mode-switch');
        if (uldEditModeSwitch) {
            uldEditModeSwitch.addEventListener('change', (e) => {
                const isEdit = e.target.checked;
                const editIcons = document.querySelectorAll('.uld-drawer-edit-icon');

                // Toggle visibility of edit icons
                editIcons.forEach(icon => {
                    icon.style.display = isEdit ? 'inline-block' : 'none';
                });

                // Reset all open inputs and bring back spans if disabling edit mode
                if (!isEdit) {
                    const fields = ['pcs', 'wgt', 'prio', 'brk', 'sts', 'rem'];
                    fields.forEach(f => {
                        const span = document.getElementById(`drawer-uld-${f}`);
                        const input = document.getElementById(`drawer-uld-${f}-edit`);
                        const editBtn = document.getElementById(`edit-uld-${f}-btn`);
                        const saveBtn = document.getElementById(`save-uld-${f}-btn`);
                        const cancelBtn = document.getElementById(`cancel-uld-${f}-btn`);

                        if(span) span.style.display = 'inline-block';
                        if(input) input.style.display = 'none';
                        if(editBtn) editBtn.style.display = 'none';
                        if(saveBtn) saveBtn.style.display = 'none';
                        if(cancelBtn) cancelBtn.style.display = 'none';
                    });
                }
            });
        }

        // Action handles for each field in ULD Drawer
        ['pcs', 'wgt', 'prio', 'brk', 'sts', 'rem'].forEach(f => {
            const span = document.getElementById(`drawer-uld-${f}`);
            const input = document.getElementById(`drawer-uld-${f}-edit`);
            const editBtn = document.getElementById(`edit-uld-${f}-btn`);
            const saveBtn = document.getElementById(`save-uld-${f}-btn`);
            const cancelBtn = document.getElementById(`cancel-uld-${f}-btn`);

            if(editBtn && input && span && saveBtn && cancelBtn) {
                editBtn.addEventListener('click', () => {
                    span.style.display = 'none';
                    editBtn.style.display = 'none';
                    
                    // Display fix for flex text inputs like Remarks vs inline configs
                    if(f === 'rem') input.style.display = 'flex';
                    else input.style.display = 'inline-block';

                    saveBtn.style.display = 'inline-block';
                    cancelBtn.style.display = 'inline-block';

                    // Re-sync input with current text correctly based on the visual span directly
                    let currValue = span.textContent.trim();
                    if (f === 'pcs') input.value = (currValue !== '--') ? currValue : '';
                    if (f === 'wgt') input.value = (currValue !== '--') ? currValue.replace(' kg', '').trim() : '';
                    if (f === 'prio') input.value = (currValue === 'Yes') ? 'yes' : 'no';
                    if (f === 'brk') input.value = (currValue === 'Break') ? 'yes' : 'no';
                    if (f === 'sts') input.value = (currValue !== '--') ? currValue.toLowerCase() : 'received';
                    if (f === 'rem') input.value = (currValue !== '--' && currValue !== 'N/A') ? currValue : '';
                    
                    input.focus();
                });

                cancelBtn.addEventListener('click', () => {
                    span.style.display = 'inline-block';
                    editBtn.style.display = 'inline-block';
                    input.style.display = 'none';
                    saveBtn.style.display = 'none';
                    cancelBtn.style.display = 'none';
                });

                saveBtn.addEventListener('click', () => {
                    let fieldName = '';
                    if (f === 'pcs') fieldName = 'pieces';
                    if (f === 'wgt') fieldName = 'weight';
                    if (f === 'prio') fieldName = 'priority';
                    if (f === 'brk') fieldName = 'break';
                    if (f === 'sts') fieldName = 'status';
                    if (f === 'rem') fieldName = 'remarks';
                    
                    let valToSave = input.value;
                    if(f === 'prio' || f === 'brk') valToSave = (input.value === 'yes');
                    window.updateDrawerUldField(fieldName, valToSave);

                    span.style.display = 'inline-block';
                    editBtn.style.display = 'inline-block';
                    input.style.display = 'none';
                    saveBtn.style.display = 'none';
                    cancelBtn.style.display = 'none';
                });
            }
        });

        // Auto-fill AWB total
        const awbNumberInput = document.getElementById('awb-number');
        if (awbNumberInput) {
            awbNumberInput.addEventListener('input', async (e) => {
                const val = e.target.value.trim().toUpperCase();
                const totalInput = document.getElementById('awb-total');

                // Si se borra o no está completo, permitimos edición libre siempre
                if (val.length < 13) {
                    totalInput.readOnly = false;
                    totalInput.style.backgroundColor = '';
                    return;
                }

                // Si ha alcanzado los 13 caracteres, buscamos si tiene "Total" ya guardado localmente en esta misma sesión
                let foundTotal = null;

                for (const u of localUlds) {
                    if (u.awbs) {
                        const foundLocal = u.awbs.find(a => a.awb_number === val);
                        if (foundLocal && foundLocal.total !== null && foundLocal.total !== undefined && foundLocal.total !== '') {
                            foundTotal = foundLocal.total;
                            break;
                        }
                    }
                }

                // Buscar en Supabase si no se halló localmente
                if (foundTotal === null) {
                    try {
                        totalInput.placeholder = 'Buscando...';
                        const spacelessVal = val.replace(/\s/g, '');
                        let { data, error } = await supabaseClient
                            .from('AWB')
                            .select('total')
                            .eq('AWB number', val)
                            .maybeSingle();
                        
                        // Query fallback for spaceless values
                        if (!data && !error && spacelessVal !== val) {
                            const res = await supabaseClient
                                .from('AWB')
                                .select('total')
                                .eq('AWB number', spacelessVal)
                                .maybeSingle();
                            data = res.data;
                            error = res.error;
                        }
                        
                        if (!error && data && data.total !== null) {
                            foundTotal = data.total;
                        }
                    } catch (err) {
                        console.error('Error fetching awb total:', err);
                    } finally {
                        totalInput.placeholder = '0.0';
                    }
                }

                if (foundTotal !== null) {
                    totalInput.value = foundTotal;
                    // Bloqueamos la edición del campo para no sobrescribir (según requerimiento)
                    totalInput.readOnly = true;
                    totalInput.style.backgroundColor = '#f1f5f9';
                }
            });
        }

        // Auto-fill AWB total para el form Global
        const gAwbNumberInput = document.getElementById('g-awb-number');
        if (gAwbNumberInput) {
            gAwbNumberInput.addEventListener('input', async (e) => {
                const val = e.target.value.trim().toUpperCase();
                const totalInput = document.getElementById('g-awb-total');

                // Si se borra o no está completo, permitimos edición libre siempre
                if (val.length < 13) {
                    totalInput.readOnly = false;
                    totalInput.style.backgroundColor = '';
                    return;
                }

                // Buscar en Supabase directamente
                let foundTotal = null;
                try {
                    totalInput.placeholder = 'Buscando...';
                    const spacelessVal = val.replace(/\s/g, '');
                    let { data, error } = await supabaseClient
                        .from('AWB')
                        .select('total')
                        .eq('AWB number', val)
                        .maybeSingle();

                    if (!data && !error && spacelessVal !== val) {
                        const res = await supabaseClient
                            .from('AWB')
                            .select('total')
                            .eq('AWB number', spacelessVal)
                            .maybeSingle();
                        data = res.data;
                        error = res.error;
                    }
                    
                    if (!error && data && data.total !== null) {
                        foundTotal = data.total;
                    }
                } catch (err) {
                    console.error('Error fetching awb total:', err);
                } finally {
                    totalInput.placeholder = '0';
                }

                if (foundTotal !== null) {
                    totalInput.value = foundTotal;
                    // Bloqueamos la edición del campo para no sobrescribir
                    totalInput.readOnly = true;
                    totalInput.style.backgroundColor = '#f1f5f9';
                }
            });
        }

        // Auto-fill AWB total para el form interno (guld)
        const guldAwbNumberInput = document.getElementById('guld-awb-number');
        if (guldAwbNumberInput) {
            guldAwbNumberInput.addEventListener('input', async (e) => {
                const val = e.target.value.trim().toUpperCase();
                const totalInput = document.getElementById('guld-awb-total');

                if (val.length < 13) {
                    totalInput.readOnly = false;
                    totalInput.style.backgroundColor = '';
                    return;
                }

                let foundTotal = null;
                try {
                    totalInput.placeholder = 'Buscando...';
                    const spacelessVal = val.replace(/\s/g, '');
                    let { data, error } = await supabaseClient
                        .from('AWB')
                        .select('total')
                        .eq('AWB number', val)
                        .maybeSingle();

                    if (!data && !error && spacelessVal !== val) {
                        const res = await supabaseClient
                            .from('AWB')
                            .select('total')
                            .eq('AWB number', spacelessVal)
                            .maybeSingle();
                        data = res.data;
                        error = res.error;
                    }
                    
                    if (!error && data && data.total !== null) {
                        foundTotal = data.total;
                    }
                } catch (err) {
                    console.error('Error fetching awb total:', err);
                } finally {
                    totalInput.placeholder = '0';
                }

                if (foundTotal !== null) {
                    totalInput.value = foundTotal;
                    totalInput.readOnly = true;
                    totalInput.style.backgroundColor = '#f1f5f9';
                }
            });
        }

        // Añadir AWB localmente
        if(addAwbBtn) {
            addAwbBtn.addEventListener('click', () => {
                const aNum = document.getElementById('awb-number').value.trim().toUpperCase();
                
                // Parse house numbers into array
                const aHouseRaw = document.getElementById('awb-house').value.trim().toUpperCase();
                const aHouseList = aHouseRaw ? aHouseRaw.split(/[\n,]+/).map(h => h.trim()).filter(h => h) : [];
                
                const aPcs = parseInt(document.getElementById('awb-pieces').value, 10);
                const aWgt = parseFloat(document.getElementById('awb-weight').value);
                const aTot = parseFloat(document.getElementById('awb-total').value);
                const aRem = document.getElementById('awb-remarks').value.trim();

                if (!currentUldIdForAwb || !aNum) return;
                if (isNaN(aTot) || aTot <= 0) { 
                    window.showValidationModal("Missing Information", "Total Pieces is required."); 
                    return; 
                }

                // Buscamos el ULD padre
                const uld = localUlds.find(u => u.id == currentUldIdForAwb || u["ULD number"] == currentUldIdForAwb || u.uld_number == currentUldIdForAwb);
                const flightUld = typeof flightLocalUlds !== 'undefined' ? flightLocalUlds.find(u => u.id == currentUldIdForAwb || u.uldNumber == currentUldIdForAwb) : null;
                if (!uld) return;

                if (!uld.awbs) uld.awbs = []; // Inicializamos si no tiene arreglo
                if (flightUld && !flightUld.awbs) flightUld.awbs = [];
                
                const awbExists = uld.awbs.some(a => a.awb_number === aNum);
                if (awbExists) {
                    window.showValidationModal("Duplicate Entry", "This AWB number is already added to this ULD.");
                    return;
                }

                const newAwb = {
                    id: Date.now(),
                    awb_number: aNum,
                    house_number: aHouseList,
                    pieces: isNaN(aPcs) ? 0 : aPcs,
                    weight: isNaN(aWgt) ? 0 : aWgt,
                    total: isNaN(aTot) ? 0 : aTot,
                    remarks: aRem
                };

                uld.awbs.push(newAwb);
                if (flightUld && flightUld !== uld) flightUld.awbs.push(newAwb);

                // Auto-calculate pieces and weight if enabled
                if (uld.isPiecesAuto || (flightUld && flightUld.isPiecesAuto)) {
                    let totalPcs = uld.awbs.reduce((sum, a) => sum + (parseInt(a.pieces, 10) || 0), 0);
                    uld.pieces = totalPcs > 0 ? totalPcs.toString() : '';
                    if (flightUld) flightUld.pieces = uld.pieces;
                    const pcsEl = document.getElementById('drawer-uld-pcs');
                    if(pcsEl) pcsEl.textContent = uld.pieces || '0';
                }
                if (uld.isWeightAuto || (flightUld && flightUld.isWeightAuto)) {
                    let totalWgt = uld.awbs.reduce((sum, a) => sum + (parseFloat(a.weight) || 0), 0);
                    uld.weight = totalWgt > 0 ? parseFloat(totalWgt.toFixed(1)).toString() : '';
                    if (flightUld) flightUld.weight = uld.weight;
                    const wgtEl = document.getElementById('drawer-uld-wgt');
                    if(wgtEl) wgtEl.textContent = (uld.weight || '0') + ' kg';
                }

                // Limpiar form AWB
                document.getElementById('awb-number').value = '';
                const houseInput = document.getElementById('awb-house');
                houseInput.value = '';
                houseInput.style.height = '33px'; // Reset automatically expanded height
                document.getElementById('awb-pieces').value = '';
                document.getElementById('awb-weight').value = '';
                
                const totalInput = document.getElementById('awb-total');
                totalInput.value = '';
                totalInput.readOnly = false;
                totalInput.style.backgroundColor = '';
                
                document.getElementById('awb-remarks').value = '';

                renderLocalAwbs();
                renderLocalUlds(); // Repintamos ULDs para actualizar el conteo en su fila
                if (typeof renderFlightLocalUlds === 'function') renderFlightLocalUlds();
            });
        }

        window.removeLocalAwb = function(uldId, awbId) {
            const uld = localUlds.find(u => u.id == uldId || u["ULD number"] == uldId || u.uld_number == uldId);
            const flightUld = typeof flightLocalUlds !== 'undefined' ? flightLocalUlds.find(u => u.id == uldId || u.uldNumber == uldId) : null;
            if(uld && uld.awbs) {
                uld.awbs = uld.awbs.filter(a => a.id !== awbId);
                if (flightUld && flightUld !== uld && flightUld.awbs) {
                    flightUld.awbs = flightUld.awbs.filter(a => a.id !== awbId);
                }
                
                if (uld.isPiecesAuto || (flightUld && flightUld.isPiecesAuto)) {
                    let totalPcs = uld.awbs.reduce((sum, a) => sum + (parseInt(a.pieces, 10) || 0), 0);
                    uld.pieces = totalPcs > 0 ? totalPcs.toString() : '';
                    if (flightUld) flightUld.pieces = uld.pieces;
                    const pcsEl = document.getElementById('drawer-uld-pcs');
                    if(pcsEl) pcsEl.textContent = uld.pieces || '0';
                }
                if (uld.isWeightAuto || (flightUld && flightUld.isWeightAuto)) {
                    let totalWgt = uld.awbs.reduce((sum, a) => sum + (parseFloat(a.weight) || 0), 0);
                    uld.weight = totalWgt > 0 ? parseFloat(totalWgt.toFixed(1)).toString() : '';
                    if (flightUld) flightUld.weight = uld.weight;
                    const wgtEl = document.getElementById('drawer-uld-wgt');
                    if(wgtEl) wgtEl.textContent = (uld.weight || '0') + ' kg';
                }
                
                renderLocalAwbs();
                renderLocalUlds(); // Por si cambió el badge de conteo
                if (typeof renderFlightLocalUlds === 'function') renderFlightLocalUlds();
            }
        }

        function renderLocalAwbs() {
            if (!drawerAwbTable) return;
            drawerAwbTable.innerHTML = '';
            
            const uld = localUlds.find(u => u.id == currentUldIdForAwb || u["ULD number"] == currentUldIdForAwb || u.uld_number == currentUldIdForAwb);
            if (!uld || !uld.awbs || uld.awbs.length === 0) {
                drawerAwbTable.innerHTML = '<tr><td colspan="4" style="padding: 16px; text-align: center; color: #94a3b8; font-size: 12px; font-style: italic;">No AWBs yet.</td></tr>';
                return;
            }

            uld.awbs.forEach((awb, index) => {
                const tr = document.createElement('tr');
                const hList = awb.house_number || [];
                const hCount = hList.length;
                const safeHStr = hList.join(',').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                const hBadge = hCount > 0 
                               ? `<span style="background:#e0e7ff; color:#4f46e5; padding:2px 6px; border-radius:10px; font-size:9px; cursor:pointer;" onclick="window.showHouseNumbersModal('${safeHStr}')" title="Click to view all">${hCount}</span>` 
                               : `<span style="color:#94a3b8; font-size:10px;">0</span>`;

                tr.innerHTML = `
                    <td style="padding: 8px 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; font-weight: 500;">
                        ${index + 1}
                    </td>
                    <td style="padding: 8px 12px; font-size: 11px; color: #334155; border-bottom: 1px solid #f1f5f9; font-weight: 500; white-space: nowrap;">
                        ${awb.awb_number}
                    </td>
                    <td style="padding: 8px 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9;">${awb.pieces}</td>
                    <td style="padding: 8px 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9;">${awb.total || '0'}</td>
                    <td style="padding: 8px 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9;">${awb.weight}</td>
                    <td style="padding: 8px 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9;">${hBadge}</td>
                    <td style="padding: 8px 12px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; max-width: 100px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="${awb.remarks || ''}">
                        ${awb.remarks || '-'}
                    </td>
                    <td style="padding: 8px 12px; font-size: 11px; border-bottom: 1px solid #f1f5f9; text-align: right;">
                        <button type="button" onclick="removeLocalAwb('${uld.id || uld["ULD number"] || uld.uld_number}', ${awb.id})" style="background: transparent; border: none; color: #ef4444; cursor: pointer;">
                            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                        </button>
                    </td>
                `;
                drawerAwbTable.appendChild(tr);
            });
        }
        // ====== FIN LÓGICA DRAWER AWB ======

        function renderLocalUlds() {
            // Obsolete for local inside flight form
        }

        // ------ LÓGICA LOCAL ULD DENTRO DEL FORM DE FLIGHT ------
        let flightLocalUlds = [];
        
        function renderFlightLocalUlds() {
            const tableBody = document.getElementById('f-uld-table-body');
            if (!tableBody) return;
            
            if (flightLocalUlds.length === 0) {
                tableBody.innerHTML = '<tr style="display: table; width: 100%; table-layout: fixed;"><td colspan="8" style="padding: 12px; text-align: center; color: #94a3b8; font-size: 12px;">No ULDs added yet.</td></tr>';
                
                // Also reset C.Break/NoBreak visual counts if Auto is active when ULD list goes empty.
                const fBreakAuto = document.getElementById('f-break-auto');
                const fBreakField = document.getElementById('f-break');
                const fNoBreakAuto = document.getElementById('f-nobreak-auto');
                const fNoBreakField = document.getElementById('f-nobreak');
                
                if (fBreakAuto && fBreakAuto.checked && fBreakField) {
                    fBreakField.value = '';
                    fBreakField.placeholder = '';
                }
                if (fNoBreakAuto && fNoBreakAuto.checked && fNoBreakField) {
                    fNoBreakField.value = '';
                    fNoBreakField.placeholder = '';
                }
                return;
            }

            // Calculate auto counts based on current flightLocalUlds
            let autoBreakCount = 0;
            let autoNoBreakCount = 0;
            flightLocalUlds.forEach(uld => {
                 if (uld.break === true || uld.break === 'true' || uld.isBreak === true || uld.isBreak === 'true') {
                     autoBreakCount++;
                 } else {
                     autoNoBreakCount++;
                 }
            });

            // Update DOM fields if auto is checked
            const fBreakAuto = document.getElementById('f-break-auto');
            const fBreakField = document.getElementById('f-break');
            const fNoBreakAuto = document.getElementById('f-nobreak-auto');
            const fNoBreakField = document.getElementById('f-nobreak');

            if (fBreakAuto && fBreakAuto.checked && fBreakField) {
                fBreakField.value = autoBreakCount;
            }
            if (fNoBreakAuto && fNoBreakAuto.checked && fNoBreakField) {
                fNoBreakField.value = autoNoBreakCount;
            }

            tableBody.innerHTML = '';
            flightLocalUlds.forEach((uld, index) => {
                const tr = document.createElement('tr');
                tr.style.display = 'table';
                tr.style.width = '100%';
                tr.style.tableLayout = 'fixed';
                tr.style.cursor = 'pointer';
                
                // Clicking opens the drawer using the uldNumber as the identifier
                tr.addEventListener('click', (e) => {
                    // Evitar que el click en "Eliminar" abra el modal también
                    if(e.target.closest('button')) return;
                    openAwbPanel(uld.uldNumber);
                });

                tr.innerHTML = `
                    <td style="padding: 10px 10px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; width: 30px; text-align: center; vertical-align: middle;">
                        ${index + 1}
                    </td>
                    <td style="padding: 10px 10px; font-size: 12px; color: #334155; border-bottom: 1px solid #f1f5f9; font-weight: 600; width: 120px; vertical-align: middle;">
                        ${uld.uldNumber}
                    </td>
                    <td style="padding: 10px 10px; font-size: 12px; color: #64748b; border-bottom: 1px solid #f1f5f9; width: 60px; vertical-align: middle; white-space: nowrap; position: relative;">
                        ${uld.pieces || '0'}
                        ${uld.isPiecesAuto ? '<span style="position: absolute; top: 4px; right: 4px; background: #e0e7ff; color: #4f46e5; width: 10px; height: 10px; border-radius: 50%; font-size: 7px; font-weight: 800; display: inline-flex; align-items: center; justify-content: center; opacity: 0.8;" title="Auto">A</span>' : ''}
                    </td>
                    <td style="padding: 10px 10px; font-size: 12px; color: #64748b; border-bottom: 1px solid #f1f5f9; width: 70px; vertical-align: middle; white-space: nowrap; position: relative;">
                        ${uld.weight || '0.0'}
                        ${uld.isWeightAuto ? '<span style="position: absolute; top: 4px; right: 4px; background: #e0e7ff; color: #4f46e5; width: 10px; height: 10px; border-radius: 50%; font-size: 7px; font-weight: 800; display: inline-flex; align-items: center; justify-content: center; opacity: 0.8;" title="Auto">A</span>' : ''}
                    </td>
                    <td style="padding: 10px 10px; font-size: 11px; border-bottom: 1px solid #f1f5f9; width: 65px; text-align: center; vertical-align: middle;">
                        ${(uld.isPriority || uld.priority) ? '<span style="color:#ef4444; font-weight:600;">Yes</span>' : '<span style="color:#94a3b8;">No</span>'}
                    </td>
                    <td style="padding: 10px 10px; font-size: 11px; border-bottom: 1px solid #f1f5f9; width: 75px; text-align: center; vertical-align: middle;">
                        ${(uld.isBreak || uld.break) ? '<span style="color:#10b981; font-weight:600;">Break</span>' : '<span style="color:#ef4444;">No Break</span>'}
                    </td>
                    <td style="padding: 10px 10px; font-size: 11px; color: #64748b; border-bottom: 1px solid #f1f5f9; vertical-align: middle; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="${uld.remarks || ''}">
                        ${uld.remarks || '-'}
                    </td>
                    <td style="padding: 10px 10px; border-bottom: 1px solid #f1f5f9; text-align: right; width: 50px; vertical-align: middle;">
                        <button type="button" onclick="removeFlightLocalUld(${index})" style="background: transparent; border: none; color: #ef4444; cursor: pointer;" title="Remove">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                        </button>
                    </td>
                `;
                tableBody.appendChild(tr);
            });
        }

        window.removeFlightLocalUld = function(index) {
            const removedUld = flightLocalUlds[index];
            if(removedUld) {
                localUlds = localUlds.filter(u => u["ULD number"] !== removedUld.uldNumber);
            }
            flightLocalUlds.splice(index, 1);
            renderFlightLocalUlds();
        };

        const addFUldBtn = document.getElementById('add-f-uld-btn');
        if (addFUldBtn) {
            addFUldBtn.addEventListener('click', () => {
                const uNum = document.getElementById('f-uld-number').value.trim().toUpperCase();
                const uPcs = document.getElementById('f-uld-pieces').value;
                const uWgt = document.getElementById('f-uld-weight').value;
                const uRem = document.getElementById('f-uld-remarks').value;
                
                const prioEl = document.getElementById('f-uld-priority');
                const uPrio = prioEl ? prioEl.checked : false;

                const breakEl = document.getElementById('f-uld-break');
                const uBreak = breakEl ? breakEl.checked : false;
                
                const pcsAutoEl = document.getElementById('f-uld-pieces-auto');
                const isPiecesAuto = pcsAutoEl ? pcsAutoEl.checked : false;
                
                const wgtAutoEl = document.getElementById('f-uld-weight-auto');
                const isWeightAuto = wgtAutoEl ? wgtAutoEl.checked : false;

                if (!uNum) return;

                const exists = flightLocalUlds.some(u => u.uldNumber === uNum);
                if (exists) {
                    window.showValidationModal("Duplicate Entry", "This ULD number is already in the list.");
                    return;
                }

                const payload = {
                    uldNumber: uNum,
                    pieces: uPcs,
                    weight: uWgt,
                    remarks: uRem,
                    priority: uPrio,
                    break: uBreak,
                    isPiecesAuto: isPiecesAuto,
                    isWeightAuto: isWeightAuto,
                    "ULD number": uNum, // Add for compatibility with drawer
                    awbs: [] // Initialize awbs array when created locally
                };

                flightLocalUlds.push(payload);
                localUlds.push(payload); // Ensure it's in localUlds so openAwbPanel detects it

                // Limpiar inline form inputs
                document.getElementById('f-uld-number').value = '';
                document.getElementById('f-uld-pieces').value = '';
                document.getElementById('f-uld-weight').value = '';
                document.getElementById('f-uld-remarks').value = '';
                if(prioEl) prioEl.checked = false;
                if(breakEl) breakEl.checked = false;
                
                renderFlightLocalUlds();
            });
        }

        const fBreakAuto = document.getElementById('f-break-auto');
        const fBreakField = document.getElementById('f-break');
        if(fBreakAuto && fBreakField) {
            fBreakAuto.addEventListener('change', (e) => {
                fBreakField.disabled = e.target.checked;
                fBreakField.style.opacity = e.target.checked ? '0.6' : '1';
                fBreakField.style.backgroundColor = e.target.checked ? '#f1f5f9' : 'white';
                fBreakField.placeholder = '';
                if(e.target.checked) fBreakField.value = '';
                if(!e.target.checked) fBreakField.focus();
            });
        }
        
        const fNoBreakAuto = document.getElementById('f-nobreak-auto');
        const fNoBreakField = document.getElementById('f-nobreak');
        if(fNoBreakAuto && fNoBreakField) {
            fNoBreakAuto.addEventListener('change', (e) => {
                fNoBreakField.disabled = e.target.checked;
                fNoBreakField.style.opacity = e.target.checked ? '0.6' : '1';
                fNoBreakField.style.backgroundColor = e.target.checked ? '#f1f5f9' : 'white';
                fNoBreakField.placeholder = '';
                if(e.target.checked) fNoBreakField.value = '';
                if(!e.target.checked) fNoBreakField.focus();
            });
        }

        const fUldPiecesAuto = document.getElementById('f-uld-pieces-auto');
        const fUldPiecesField = document.getElementById('f-uld-pieces');
        if(fUldPiecesAuto && fUldPiecesField) {
            fUldPiecesAuto.addEventListener('change', (e) => {
                fUldPiecesField.disabled = e.target.checked;
                fUldPiecesField.style.opacity = e.target.checked ? '0.6' : '1';
                fUldPiecesField.style.backgroundColor = e.target.checked ? '#f1f5f9' : 'white';
                fUldPiecesField.placeholder = '';
                if(e.target.checked) fUldPiecesField.value = '';
                if(!e.target.checked) fUldPiecesField.focus();
            });
        }
        
        const fUldWeightAuto = document.getElementById('f-uld-weight-auto');
        const fUldWeightField = document.getElementById('f-uld-weight');
        if(fUldWeightAuto && fUldWeightField) {
            fUldWeightAuto.addEventListener('change', (e) => {
                fUldWeightField.disabled = e.target.checked;
                fUldWeightField.style.opacity = e.target.checked ? '0.6' : '1';
                fUldWeightField.style.backgroundColor = e.target.checked ? '#f1f5f9' : 'white';
                fUldWeightField.placeholder = '';
                if(e.target.checked) fUldWeightField.value = '';
                if(!e.target.checked) fUldWeightField.focus();
            });
        }
        
        const gUldPiecesAuto = document.getElementById('g-uld-pieces-auto');
        const gUldPiecesField = document.getElementById('g-uld-pieces');
        if(gUldPiecesAuto && gUldPiecesField) {
            gUldPiecesAuto.addEventListener('change', (e) => {
                gUldPiecesField.disabled = e.target.checked;
                gUldPiecesField.style.opacity = e.target.checked ? '0.6' : '1';
                gUldPiecesField.style.backgroundColor = e.target.checked ? '#f1f5f9' : 'white';
                gUldPiecesField.placeholder = '';
                if(e.target.checked) gUldPiecesField.value = '';
                if(!e.target.checked) gUldPiecesField.focus();
            });
        }
        
        const gUldWeightAuto = document.getElementById('g-uld-weight-auto');
        const gUldWeightField = document.getElementById('g-uld-weight');
        if(gUldWeightAuto && gUldWeightField) {
            gUldWeightAuto.addEventListener('change', (e) => {
                gUldWeightField.disabled = e.target.checked;
                gUldWeightField.style.opacity = e.target.checked ? '0.6' : '1';
                gUldWeightField.style.backgroundColor = e.target.checked ? '#f1f5f9' : 'white';
                gUldWeightField.placeholder = '';
                if(e.target.checked) gUldWeightField.value = '';
                if(!e.target.checked) gUldWeightField.focus();
            });
        }


        if(addFlightForm) {
            addFlightForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                
                const fCarrier = document.getElementById('f-carrier').value.trim();
                const fNumber = document.getElementById('f-number').value.trim();
                let fBreak = document.getElementById('f-break').value.trim();
                let fNoBreak = document.getElementById('f-nobreak').value.trim();
                const isBreakAuto = document.getElementById('f-break-auto')?.checked;
                const isNoBreakAuto = document.getElementById('f-nobreak-auto')?.checked;
                const fDate = document.getElementById('f-date').value.trim();
                const fTime = document.getElementById('f-time').value.trim();
                const fRemarks = document.getElementById('f-remarks').value;
                const fStatus = document.getElementById('f-status').value;
                
                let calculatedBreak = 0;
                let calculatedNoBreak = 0;
                
                if (flightLocalUlds && flightLocalUlds.length > 0) {
                    flightLocalUlds.forEach(uld => {
                        // Assuming uld.isBreak or uld.break tracks the status. It's stored as boolean normally.
                        if (uld.break === true || uld.break === 'true' || uld.isBreak === true || uld.isBreak === 'true') {
                            calculatedBreak++;
                        } else {
                            calculatedNoBreak++;
                        }
                    });
                }
                
                if (isBreakAuto) fBreak = calculatedBreak;
                if (isNoBreakAuto) fNoBreak = calculatedNoBreak;
                
                if (!fCarrier) {
                    window.showValidationModal("Missing Information", "Carrier is required.");
                    return;
                }
                if (!fNumber) {
                    window.showValidationModal("Missing Information", "Number is required.");
                    return;
                }
                if (!isBreakAuto && (fBreak === null || fBreak === '')) {
                    window.showValidationModal("Missing Information", "C. Break is required.");
                    return;
                }
                if (!isNoBreakAuto && (fNoBreak === null || fNoBreak === '')) {
                    window.showValidationModal("Missing Information", "C. No Break is required.");
                    return;
                }
                if (!fDate) {
                    window.showValidationModal("Missing Information", "Date Arrived is required.");
                    return;
                }
                if (!fTime) {
                    window.showValidationModal("Missing Information", "Time Arrived is required.");
                    return;
                }
                
                const tempUldNum = document.getElementById('f-uld-number').value.trim();
                const tempUldPcs = document.getElementById('f-uld-pieces').value.trim();
                const tempUldWgt = document.getElementById('f-uld-weight').value.trim();
                
                if (tempUldNum || tempUldPcs || tempUldWgt) {
                    window.showValidationModal("Pending ULD", "You have data entered in the ULD fields. Please click '+ Add ULD' to save it, or clear the fields to proceed.");
                    return;
                }
                
                const submitBtn = addFlightForm.querySelector('button[type="submit"]');
                const originalText = submitBtn.textContent;
                submitBtn.disabled = true;
                submitBtn.textContent = 'Guardando...';

                try {
                    // Preparamos payload basado en las posibles columnas
                    const payload = {
                        carrier: fCarrier,
                        number: fNumber,
                        "cant-break": fBreak,
                        "cant-noBreak": fNoBreak,
                        "date-arrived": fDate,
                        "time-arrived": fTime,
                        remarks: fRemarks,
                        status: fStatus
                    };
                    
                    // Supabase Inserción Datos Principales del Vuelo (Flight)
                    let response = await supabaseClient.from('Flight').insert([payload]).select();
                    
                    // Si falla porque no existe la tabla, intentamos en fonts (que es un error común de pluralización)
                    if (response.error) {
                        console.log("Error insertando en 'Flight', probando en 'flights'...");
                        response = await supabaseClient.from('flights').insert([payload]).select();
                        
                        if (response.error) {
                            console.error('%c[ERROR AL GUARDAR VUELO]', 'color:red; font-size:14px;', response.error);
                            throw new Error('Flight save error: ' + response.error.message);
                        }
                    }
                    console.log('%c[VUELO GUARDADO CON ÉXITO EN DB] ID:', 'color:green; font-weight:bold;', response.data[0]);

                    // Save local ULDs mapped to this new flight reference
                    if (flightLocalUlds.length > 0) {
                        try {
                            const flightRefString = `${fCarrier} ${fNumber} ${fDate}`.trim();
                            
                            const insertedFlightId = (response.data && response.data.length > 0) ? response.data[0].id : null;

                            for (const uld of flightLocalUlds) {
                                const uldPayload = {
                                    "ULD number": uld.uldNumber,
                                    refCarrier: fCarrier,
                                    refNumber: fNumber,
                                    refDate: fDate,
                                    pieces: uld.pieces ? parseInt(uld.pieces, 10) : 0,
                                    weight: uld.weight ? parseFloat(uld.weight) : 0,
                                    remarks: uld.remarks || null,
                                    isPriority: uld.priority || false,
                                    isBreak: uld.break || false
                                };
                                const uldRes = await supabaseClient.from('ULD').insert([uldPayload]).select();
                                if (uldRes.error) {
                                    console.error("Error al insertar ULD del vuelo:", uldRes.error);
                                } else {
                                    // Save AWBs inside this ULD
                                    if (uld.awbs && uld.awbs.length > 0) {
                                        for (const awb of uld.awbs) {
                                            try {
                                                // 1. Check if AWB already exists in database
                                                const { data: existingAwb, error: fetchErr } = await supabaseClient
                                                    .from('AWB')
                                                    .select('*')
                                                    .eq('AWB number', awb.awb_number)
                                                    .maybeSingle();

                                                let currentDataAWB = [];
                                                let isUpdate = false;

                                                if (!fetchErr && existingAwb) {
                                                    isUpdate = true;
                                                    // Parse existing data if it's already an array, else create empty array
                                                    if (Array.isArray(existingAwb['data-AWB'])) {
                                                        currentDataAWB = existingAwb['data-AWB'];
                                                    } else if (existingAwb['data-AWB']) {
                                                        try {
                                                            currentDataAWB = JSON.parse(existingAwb['data-AWB']);
                                                        } catch(e) { /* ignore */ }
                                                    }
                                                }

                                                // 2. Create the new item block for this specific entry
                                                const newAwbItem = {
                                                    refCarrier: fCarrier,
                                                    refNumber: fNumber,
                                                    refDate: fDate,
                                                    refULD: uld.uldNumber,
                                                    pieces: awb.pieces,
                                                    weight: awb.weight,
                                                    remarks: awb.remarks || null,
                                                    isBreak: uld.break || uld.isBreak || false,
                                                    house_number: awb.house_number // is already an array
                                                };

                                                currentDataAWB.push(newAwbItem);

                                                // 3. Update or Insert
                                                if (isUpdate) {
                                                    const updateRes = await supabaseClient.from('AWB')
                                                        .update({
                                                            total: awb.total,
                                                            "data-AWB": currentDataAWB
                                                        })
                                                        .eq('AWB number', awb.awb_number);
                                                    
                                                    if (updateRes.error) console.error("Error updating existing AWB:", updateRes.error);
                                                } else {
                                                    // Insert new document
                                                    const insertPayload = {
                                                        "AWB number": awb.awb_number,
                                                        total: awb.total,
                                                        "data-AWB": currentDataAWB
                                                    };
                                                    const insertRes = await supabaseClient.from('AWB').insert([insertPayload]);
                                                    if (insertRes.error) console.error("Error inserting new AWB:", insertRes.error);
                                                }
                                            } catch (err) {
                                                console.error("Unknown error processing AWB:", err);
                                            }
                                        }
                                    }
                                }
                            }
                        } catch (e) {
                            console.error("Error guardando ULDs y AWBs:", e);
                        }
                    }

                    flightLocalUlds = [];
                    renderFlightLocalUlds();
                    
                    addFlightForm.reset();
                    ['f-break-auto', 'f-nobreak-auto', 'f-uld-pieces-auto', 'f-uld-weight-auto'].forEach(id => {
                        const el = document.getElementById(id);
                        if (el) el.dispatchEvent(new Event('change'));
                    });

                    const awbNumEl = document.getElementById('awb-number');
                    if (awbNumEl) awbNumEl.value = '';
                    const awbHouseEl = document.getElementById('awb-house');
                    if (awbHouseEl) { awbHouseEl.value = ''; awbHouseEl.style.height = '33px'; }
                    const awbPcsEl = document.getElementById('awb-pieces');
                    if (awbPcsEl) awbPcsEl.value = '';
                    const awbWgtEl = document.getElementById('awb-weight');
                    if (awbWgtEl) awbWgtEl.value = '';
                    const awbTotEl = document.getElementById('awb-total');
                    if (awbTotEl) { awbTotEl.value = ''; awbTotEl.readOnly = false; awbTotEl.style.backgroundColor = 'white'; awbTotEl.placeholder = ''; }
                    const awbRemEl = document.getElementById('awb-remarks');
                    if (awbRemEl) awbRemEl.value = '';
                    
                    // SUCCESS OVERLAY
                    const overlay = document.createElement('div');
                    overlay.style.cssText = `
                        position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                        background: rgba(255, 255, 255, 0.85); z-index: 99999;
                        display: flex; align-items: center; justify-content: center;
                        backdrop-filter: blur(4px); opacity: 0; transition: opacity 0.3s ease;
                    `;
                    overlay.innerHTML = `
                        <div style="background: white; padding: 32px 48px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); display: flex; flex-direction: column; align-items: center; gap: 16px; transform: scale(0.9); transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);">
                            <div style="width: 64px; height: 64px; background: #10b981; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </div>
                            <h2 style="margin: 0; color: #0f172a; font-size: 20px; font-weight: 700;">¡Guardado!</h2>
                            <p style="margin: 0; color: #64748b; font-size: 14px;">El vuelo ha sido registrado con éxito.</p>
                        </div>
                    `;
                    document.body.appendChild(overlay);

                    // Animate in
                    requestAnimationFrame(() => {
                        overlay.style.opacity = '1';
                        overlay.firstElementChild.style.transform = 'scale(1)';
                    });

                    // Update UI gracefully
                    if (window.fetchFlights) window.fetchFlights();
                    
                    // Remove overlay and hide popup slowly
                    setTimeout(() => {
                        overlay.style.opacity = '0';
                        overlay.firstElementChild.style.transform = 'scale(0.9)';
                        setTimeout(() => {
                            overlay.remove();
                            hideFlightForm();
                        }, 300);
                    }, 1500);

                } catch (err) {
                    alert('Error al guardar: ' + err.message + '\n\nAsegúrate de que la tabla Flight exista en la base de datos pública y tengas permisos INSERT.');
                } finally {
                    submitBtn.disabled = false;
                    submitBtn.textContent = originalText;
                }
            });
        }
        // ---------- FIN LÓGICA AÑADIR VUELO ----------

        // ---------- LÓGICA DE ULD (GLOBAL) ----------
        const addUldGlobalForm = document.getElementById('add-uld-global-form');
        const globalUldTableBody = document.getElementById('global-uld-table-body');
        const gUldFlightSelect = document.getElementById('g-uld-flight');

        // Búsqueda ULD Local y Filtros de Status
        const searchUldInput = document.getElementById('uld-search-main');
        const uldStatusTabs = document.querySelectorAll('#uld-status-tabs .status-tab');
        const uldFilterBreakSelect = document.getElementById('uld-filter-break');
        let currentUldFilterStatus = 'all';

        function filterGlobalUlds() {
            const term = (searchUldInput ? searchUldInput.value : '').toLowerCase().replace(/\s+/g, '');
            const rows = globalUldTableBody.querySelectorAll('tr');
            const breakFilterVal = uldFilterBreakSelect ? uldFilterBreakSelect.value : 'all';

            rows.forEach(row => {
                if (row.querySelector('.loading-td')) return;

                const text = row.textContent.toLowerCase().replace(/\s+/g, '');
                const matchesSearch = text.includes(term);
                
                const rowStatus = row.getAttribute('data-status') ? row.getAttribute('data-status').toLowerCase() : 'received';
                const matchesStatus = (currentUldFilterStatus === 'all' || rowStatus === currentUldFilterStatus);
                
                let matchesBreak = true;
                if (breakFilterVal !== 'all') {
                    const isBreakRow = row.getAttribute('data-break') === 'true';
                    if (breakFilterVal === 'break' && !isBreakRow) matchesBreak = false;
                    if (breakFilterVal === 'nobreak' && isBreakRow) matchesBreak = false;
                }

                row.style.display = (matchesSearch && matchesStatus && matchesBreak) ? '' : 'none';
            });
        }

        if (searchUldInput) {
            searchUldInput.addEventListener('keyup', filterGlobalUlds);
        }
        
        if (uldFilterBreakSelect) {
            uldFilterBreakSelect.addEventListener('change', filterGlobalUlds);
        }

        if (uldStatusTabs) {
            uldStatusTabs.forEach(tab => {
                tab.addEventListener('click', (e) => {
                    // Update active styles
                    uldStatusTabs.forEach(t => {
                        t.classList.remove('active');
                        t.style.background = 'transparent';
                        t.style.color = '#64748b';
                        t.style.border = '1px solid #e2e8f0';
                    });
                    
                    e.currentTarget.classList.add('active');
                    e.currentTarget.style.background = '#e2e8f0';
                    e.currentTarget.style.color = '#334155';
                    e.currentTarget.style.border = 'none';

                    // Update filter status and re-filter
                    currentUldFilterStatus = e.currentTarget.getAttribute('data-status').toLowerCase();
                    filterGlobalUlds();
                    
                    const displayState = currentUldFilterStatus === 'ready' ? 'table-cell' : 'none';
                    document.querySelectorAll('.ready-checkbox-col').forEach(c => c.style.display = displayState);
                    
                    const selectAll = document.getElementById('global-uld-select-all');
                    if (selectAll) selectAll.checked = false;
                    
                    if (typeof updateBulkDeleteBtnVisibility === 'function') {
                        updateBulkDeleteBtnVisibility();
                    }
                });
            });
        }
        
        function updateBulkDeleteBtnVisibility() {
            const btn = document.getElementById('bulk-delete-ready-uld-btn');
            const countDisplay = document.getElementById('bulk-delete-ready-count');
            if(!btn) return;
            const checkedBoxes = document.querySelectorAll('.ready-uld-checkbox:checked');
            let visibleCheckedCount = 0;
            checkedBoxes.forEach(cb => {
                const tr = cb.closest('tr');
                if (tr && tr.style.display !== 'none') visibleCheckedCount++;
            });
            if(visibleCheckedCount > 0 && currentUldFilterStatus === 'ready') {
                if (countDisplay) {
                    countDisplay.textContent = visibleCheckedCount;
                }
                btn.style.display = 'flex';
            } else {
                if (countDisplay) {
                    countDisplay.textContent = '0';
                }
                btn.style.display = 'none';
            }
        }
        
        if (globalUldTableBody) {
            globalUldTableBody.addEventListener('change', (e) => {
                if (e.target && e.target.classList.contains('ready-uld-checkbox')) {
                    updateBulkDeleteBtnVisibility();
                }
            });
        }
        
        const globalUldSelectAll = document.getElementById('global-uld-select-all');
        if (globalUldSelectAll) {
            globalUldSelectAll.addEventListener('change', (e) => {
                const checked = e.target.checked;
                const checkboxes = document.querySelectorAll('.ready-uld-checkbox');
                checkboxes.forEach(cb => {
                    const tr = cb.closest('tr');
                    // Only check if the row is currently visible
                    if (tr && tr.style.display !== 'none') {
                        cb.checked = checked;
                    }
                });
                updateBulkDeleteBtnVisibility();
            });
        }

        const bulkDeleteBtn = document.getElementById('bulk-delete-ready-uld-btn');
        const bulkConfirmOverlay = document.getElementById('bulk-delete-confirm-overlay');
        const bulkConfirmCount = document.getElementById('bulk-delete-confirm-count');
        const bulkCancelBtn = document.getElementById('bulk-delete-cancel-btn');
        const bulkConfirmFinalBtn = document.getElementById('bulk-delete-confirm-btn');

        if(bulkDeleteBtn && bulkConfirmOverlay && bulkConfirmCount && bulkCancelBtn && bulkConfirmFinalBtn) {
            bulkDeleteBtn.addEventListener('click', () => {
                const checkedBoxes = document.querySelectorAll('.ready-uld-checkbox:checked');
                const idsToDelete = [];
                checkedBoxes.forEach(cb => {
                    const tr = cb.closest('tr');
                    if (tr && tr.style.display !== 'none') {
                        idsToDelete.push(cb.value);
                    }
                });
                
                if (idsToDelete.length === 0) return;
                
                bulkConfirmCount.textContent = idsToDelete.length;
                
                // Show the modal
                bulkConfirmOverlay.style.display = 'flex';
                setTimeout(() => {
                    const modalInner = bulkConfirmOverlay.querySelector('div');
                    if(modalInner) {
                        modalInner.style.opacity = '1';
                        modalInner.style.transform = 'scale(1)';
                    }
                }, 10);
                
                function closeModal() {
                    const modalInner = bulkConfirmOverlay.querySelector('div');
                    if(modalInner) {
                        modalInner.style.opacity = '0';
                        modalInner.style.transform = 'scale(0.95)';
                    }
                    setTimeout(() => {
                        bulkConfirmOverlay.style.display = 'none';
                    }, 200);
                }

                bulkCancelBtn.onclick = closeModal;
                
                bulkConfirmFinalBtn.onclick = async () => {
                    bulkConfirmFinalBtn.innerHTML = 'Deleting...';
                    bulkConfirmFinalBtn.disabled = true;

                    try {
                        for (const id of idsToDelete) {
                            await supabaseClient.from('ULD').delete().eq('id', id);
                        }
                    } catch(err) {
                        console.error('Error deleting ULDs:', err);
                        alert("A network error occurred while deleting items.");
                    }

                    closeModal();
                    bulkConfirmFinalBtn.innerHTML = 'Yes, delete';
                    bulkConfirmFinalBtn.disabled = false;
                    
                    if (globalUldSelectAll) globalUldSelectAll.checked = false;
                    document.querySelectorAll('.ready-uld-checkbox:checked').forEach(cb => cb.checked = false);
                    updateBulkDeleteBtnVisibility();
                    
                    if(typeof window.fetchGlobalUlds === 'function') {
                        window.fetchGlobalUlds();
                    }
                };
            });
        }

        async function fetchGlobalUlds() {
            window.fetchGlobalUlds = fetchGlobalUlds;
            if (!globalUldTableBody) return;
            try {
                // Hacer el fetch directo y único a la tabla ULD
                let uldRes = await supabaseClient.from('ULD').select('*');

                if (uldRes.error) {
                    console.error("Error al obtener ULDs:", uldRes.error);
                    globalUldTableBody.innerHTML = '<tr><td colspan="10">Error al cargar listado de ULDs de la base de datos.</td></tr>';
                    return;
                }

                const ulds = uldRes.data || [];
                localUlds = ulds; // Cache them globally for the drawer
                globalUldTableBody.innerHTML = '';

                if (ulds.length === 0) {
                    globalUldTableBody.innerHTML = '<tr><td colspan="10" style="text-align:center; padding: 20px; color: #94a3b8;">No ULDs available.</td></tr>';
                    return;
                }

                ulds.forEach((uld, index) => {
                    const tr = document.createElement('tr');
                    tr.style.cursor = 'pointer';
                    
                    const uNumber = uld["ULD number"] || uld.uld_number || uld.id || '-';
                    tr.addEventListener('click', () => {
                        const identifier = uld.id || uNumber;
                        if(identifier !== '-') window.openAwbPanelReadOnly(identifier);
                    });
                    
                    const fRef = (uld.refCarrier && uld.refNumber) ? `${uld.refCarrier} ${uld.refNumber}` : (uld.refFlight || uld.flight_id || '-');
                    const pcs = uld.pieces || '0';
                    const wgt = uld.weight || '0';
                    const prio = (uld.isPriority || uld.priority) ? '<span style="color:#ef4444; font-weight:bold;">Yes</span>' : 'No';
                    const brk = (uld.isBreak || uld.break) ? '<span style="background: #d1fae5; color: #059669; padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: 600; display: inline-block; width: 75px; text-align: center; box-sizing: border-box; white-space: nowrap;">BREAK</span>' : '<span style="background: #ffe4e6; color: #e11d48; padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: 600; display: inline-block; width: 75px; text-align: center; box-sizing: border-box; white-space: nowrap;">NO-BREAK</span>';
                    const rem = uld.remarks || '-';
                    const rawStatus = (uld.status || uld.Status || 'received').toLowerCase();
                    let statusBadgeHtml = window.getULDStatusBadgeHtml(rawStatus);

                    tr.setAttribute('data-status', rawStatus);
                    tr.setAttribute('data-break', (uld.isBreak || uld.break) ? 'true' : 'false');
                    tr.innerHTML = `
                        <td style="text-align: center; color: #94a3b8; font-weight: 500;">${index + 1}</td>
                        <td style="font-weight: 600; color: #334155; white-space: nowrap;">${uNumber}</td>
                        <td style="color: #64748b; white-space: nowrap;">${fRef}</td>
                        <td style="text-align: center;">${pcs}</td>
                        <td style="text-align: center;">${wgt}</td>
                        <td style="text-align: center;">${prio}</td>
                        <td style="text-align: center;">${brk}</td>
                        <td style="width: 100%; max-width: 0;"><span style="color:#64748b; display:block; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; width:100%;" title="${rem}">${rem}</span></td>
                        <td style="text-align: center;">${statusBadgeHtml}</td>
                        <td class="ready-checkbox-col" style="display: ${currentUldFilterStatus === 'ready' ? 'table-cell' : 'none'}; text-align: center;" onclick="event.stopPropagation();">
                            <input type="checkbox" class="ready-uld-checkbox" value="${uld.id}" style="width: 16px; height: 16px; cursor: pointer; accent-color: #4f46e5; outline: none;">
                        </td>
                    `;
                    globalUldTableBody.appendChild(tr);
                });

            } catch (err) {
                globalUldTableBody.innerHTML = '<tr><td colspan="10">Error cargando ULDs.</td></tr>';
            }
        }

        // Llenar Dropdown de Vuelos
        async function populateFlightDropdownForUld() {
            if(!gUldFlightSelect) return;
            try {
                let fRes = await supabaseClient.from('Flight').select('id, number, carrier, "date-arrived"');
                if (fRes.error) fRes = await supabaseClient.from('flights').select('id, number, carrier, "date-arrived"');
                
                if(!fRes.error && fRes.data) {
                    gUldFlightSelect.innerHTML = '<option value="" selected>No Flight</option>';
                    fRes.data.forEach(f => {
                        const opt = document.createElement('option');
                        
                        const carrier = f.carrier || '';
                        const number = f.number || 'Unnamed';
                        let date = f['date-arrived'] || '';
                        
                        // Si hay fecha, mostramos de forma legible
                        if (date) {
                            date = new Date(date + 'T12:00:00').toLocaleDateString();
                        }
                        
                        // El value guardará los datos estructurados en JSON
                        const combinedText = `${carrier} ${number} ${date}`.trim();
                        opt.value = JSON.stringify({carrier, number, date}); 
                        opt.textContent = combinedText;
                        gUldFlightSelect.appendChild(opt);
                    });
                }
            } catch (e) {
                console.log('No pudimos rellenar el select de vuelos', e);
            }
        }

        // Llenar Dropdown de Vuelos para AWB Independiente
        window.populateFlightDropdownForAwb = async function() {
            const gAwbFlightSelect = document.getElementById('g-awb-flight');
            if(!gAwbFlightSelect) return;
            try {
                let fRes = await supabaseClient.from('Flight').select('id, number, carrier, "date-arrived"');
                if (fRes.error) fRes = await supabaseClient.from('flights').select('id, number, carrier, "date-arrived"');
                
                if(!fRes.error && fRes.data) {
                    gAwbFlightSelect.innerHTML = '<option value="" selected>No Flight (Standalone)</option>';
                    fRes.data.forEach(f => {
                        const opt = document.createElement('option');
                        const carrier = f.carrier || '';
                        const number = f.number || 'Unnamed';
                        let date = f['date-arrived'] || '';
                        if (date) date = new Date(date + 'T12:00:00').toLocaleDateString();
                        
                        const combinedText = `${carrier} ${number} ${date}`.trim();
                        opt.value = JSON.stringify({carrier, number, date}); 
                        opt.textContent = combinedText;
                        gAwbFlightSelect.appendChild(opt);
                    });
                }
            } catch (e) {
                console.log('No pudimos rellenar el select de vuelos AWB', e);
            }
        };

        // Global AWB Items state
        window.globalAwbItems = { agi: [], pre: [], crate: [], box: [], other: [] };

        window.addGlobalAwbItem = function(type) {
            const input = document.getElementById('g-awb-' + type);
            if (!input) return;
            const qty = parseInt(input.value, 10);
            if (isNaN(qty) || qty <= 0) return;
            
            if (type === 'agi') {
                window.globalAwbItems[type].push({ qty: qty, loc: '' });
            } else {
                window.globalAwbItems[type] = [{ qty: qty, loc: '' }];
            }
            
            input.value = '';
            window.renderGlobalAwbItems();
        };

        window.updateGlobalAwbItemLoc = function(type, index, value) {
            window.globalAwbItems[type][index].loc = value;
        };

        window.removeGlobalAwbItem = function(type, index) {
            window.globalAwbItems[type].splice(index, 1);
            window.renderGlobalAwbItems();
        };

        window.renderGlobalAwbItems = function() {
            let totalChecked = 0;
            const listContainer = document.getElementById('g-awb-added-list');
            const totalEl = document.getElementById('g-awb-total-checked');
            if (!listContainer) return;

            ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                window.globalAwbItems[type].forEach(item => {
                    totalChecked += item.qty;
                });
            });

            const labelsMap = {
                agi: 'Agi Skid',
                pre: 'Pre Skid',
                crate: 'Crates',
                box: 'Boxes',
                other: 'Other'
            };

            let html = '';
            ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
                const items = window.globalAwbItems[type];
                if (items.length > 0) {
                    
                    const isStandardLoc = (loc) => ['', '15-25C', '2-8C', 'PSV', 'DG', 'Oversize', 'Small R', 'Live'].includes(loc);

                    const selectOptionsHtml = (currLoc) => {
                        const std = isStandardLoc(currLoc) ? currLoc : '';
                        return `
                        <option value="" ${std===''?'selected':''}>Select Loc</option>
                        <option value="15-25C" ${std==='15-25C'?'selected':''}>15-25*C</option>
                        <option value="2-8C" ${std==='2-8C'?'selected':''}>2-8*C</option>
                        <option value="PSV" ${std==='PSV'?'selected':''}>PSV</option>
                        <option value="DG" ${std==='DG'?'selected':''}>DG</option>
                        <option value="Oversize" ${std==='Oversize'?'selected':''}>Oversize</option>
                        <option value="Small R" ${std==='Small R'?'selected':''}>Small rack</option>
                        <option value="Live" ${std==='Live'?'selected':''}>Animal Live</option>
                    `};

                    if (type === 'agi') {
                        let groupInnerHtml = '';
                        items.forEach((item, index) => {
                            groupInnerHtml += `
                                <div style="display: flex; flex-direction: column; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px 12px; margin-bottom: 6px; animation: fadeIn 0.15s ease;">
                                    <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                                        <div style="display: flex; align-items: center; gap: 8px; flex: 1;">
                                            <span style="font-size: 12px; color: #64748b; font-weight: 600; min-width: 20px; text-align: left;">#${index + 1}</span>
                                            <span style="font-size: 14px; font-weight: 700; color: #0f172a; margin-left: 8px;">${item.qty} pcs</span>
                                        </div>
                                        <button onclick="window.removeGlobalAwbItem('${type}', ${index})" style="border:none; background:none; color: #94a3b8; cursor: pointer; font-size: 18px; line-height: 1; outline: none; transition: color 0.1s; padding-right: 4px; width: 24px;" onmouseover="this.style.color='#ef4444'" onmouseout="this.style.color='#94a3b8'">&times;</button>
                                    </div>
                                    <div style="display: flex; align-items: center; gap: 4px; margin-top: 6px; border-top: 1px dashed #e2e8f0; padding-top: 6px;">
                                        <label style="font-size: 11px; font-weight: 600; color: #64748b; margin: 0;">Location:</label>
                                        <select onchange="this.nextElementSibling.value=''; window.updateGlobalAwbItemLoc('${type}', ${index}, this.value)" style="width: 85px; padding: 4px 6px; border-radius: 4px; border: 1px solid #e2e8f0; font-size: 11px; outline: none; background: #f8fafc; color: #0f172a;">
                                            ${selectOptionsHtml(item.loc)}
                                        </select>
                                        <input type="text" placeholder="Other..." value="${isStandardLoc(item.loc) ? '' : item.loc}" oninput="this.previousElementSibling.value=''; window.updateGlobalAwbItemLoc('${type}', ${index}, this.value.toUpperCase())" style="flex: 1; min-width: 50px; padding: 4px 6px; border-radius: 4px; border: 1px solid #e2e8f0; font-size: 11px; outline: none; text-transform: uppercase;">
                                    </div>
                                </div>
                            `;
                        });

                        html += `
                            <div style="background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; margin-bottom: 8px; animation: fadeIn 0.2s ease;">
                                <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 6px;">
                                    <div style="background: #e2e8f0; border-radius: 12px; min-width: 24px; height: 18px; padding: 0 4px; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 11px; color: #334155;">
                                        ${items.length}
                                    </div>
                                    <span style="font-weight: 600; font-size: 12px; color: #0f172a; text-transform: uppercase;">${labelsMap[type]}</span>
                                </div>
                                <div style="display: flex; flex-direction: column; gap: 0;">
                                    ${groupInnerHtml}
                                </div>
                            </div>
                        `;
                    } else {
                        // Condensed block for non-agi items: "23 PRE SKID" [x]
                        html += `
                            <div style="background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 8px 12px; margin-bottom: 8px; animation: fadeIn 0.15s ease; display: flex; flex-direction: column;">
                                <div style="display: flex; justify-content: space-between; align-items: center;">
                                    <div style="display: flex; align-items: center; gap: 6px;">
                                        <span style="font-size: 14px; font-weight: 700; color: #0f172a;">${items[0].qty}</span>
                                        <span style="font-weight: 600; font-size: 13px; color: #475569; text-transform: uppercase;">${labelsMap[type]}</span>
                                    </div>
                                    <button onclick="window.removeGlobalAwbItem('${type}', 0)" style="border:none; background:none; color: #94a3b8; cursor: pointer; font-size: 20px; line-height: 1; outline: none; transition: color 0.1s; padding-right: 4px; width: 24px;" onmouseover="this.style.color='#ef4444'" onmouseout="this.style.color='#94a3b8'">&times;</button>
                                </div>
                                <div style="display: flex; align-items: center; gap: 4px; margin-top: 6px; border-top: 1px dashed #e2e8f0; padding-top: 6px;">
                                    <label style="font-size: 11px; font-weight: 600; color: #64748b; margin: 0;">Location:</label>
                                    <select onchange="this.nextElementSibling.value=''; window.updateGlobalAwbItemLoc('${type}', 0, this.value)" style="width: 85px; padding: 4px 6px; border-radius: 4px; border: 1px solid #e2e8f0; font-size: 11px; outline: none; background: #f8fafc; color: #0f172a;">
                                        ${selectOptionsHtml(items[0].loc)}
                                    </select>
                                    <input type="text" placeholder="Other..." value="${isStandardLoc(items[0].loc) ? '' : items[0].loc}" oninput="this.previousElementSibling.value=''; window.updateGlobalAwbItemLoc('${type}', 0, this.value.toUpperCase())" style="flex: 1; min-width: 50px; padding: 4px 6px; border-radius: 4px; border: 1px solid #e2e8f0; font-size: 11px; outline: none; text-transform: uppercase;">
                                </div>
                            </div>
                        `;
                    }
                }
            });

            if (html === '') {
                html = '<div style="font-size: 12px; color: #94a3b8; font-style: italic;">No items added yet.</div>';
            }

            listContainer.innerHTML = html;
            if (totalEl) totalEl.textContent = totalChecked;
        };

        // Capturar Formulario AWB Global
        const addAwbGlobalForm = document.getElementById('add-awb-global-form');
        if (addAwbGlobalForm) {
            addAwbGlobalForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const saveBtn = document.getElementById('save-new-awb-global-btn');
                const originalBtnText = saveBtn.textContent;
                saveBtn.textContent = 'Guardando...';
                saveBtn.disabled = true;

                try {
                    const number = document.getElementById('g-awb-number').value.trim().toUpperCase();
                    const flightCombo = document.getElementById('g-awb-flight').value;
                    let refCarrier = null, refNumber = null, refDate = null;
                    if (flightCombo) {
                        try {
                            const parsed = JSON.parse(flightCombo);
                            refCarrier = parsed.carrier; refNumber = parsed.number; refDate = parsed.date;
                        } catch(e) {}
                    }

                    const uld = document.getElementById('g-awb-uld').value.trim().toUpperCase();
                    const pcs = document.getElementById('g-awb-pieces').value;
                    const tot = document.getElementById('g-awb-total').value;
                    const wgt = document.getElementById('g-awb-weight').value;
                    const hou = document.getElementById('g-awb-house').value.trim().toUpperCase();
                    const rem = document.getElementById('g-awb-remarks').value;

                    // Data coordinator fields
                    const agiArr = window.globalAwbItems.agi.map(i => i.qty);
                    const preArr = window.globalAwbItems.pre.map(i => i.qty);
                    const boxArr = window.globalAwbItems.box.map(i => i.qty);
                    const crtArr = window.globalAwbItems.crate.map(i => i.qty);
                    const othArr = window.globalAwbItems.other.map(i => i.qty);

                    let itemLocations = {};
                    ['agi', 'pre', 'box', 'crate', 'other'].forEach(t => {
                        window.globalAwbItems[t].forEach((item, index) => {
                            if (item.loc) {
                                itemLocations[`${t}-${index}`] = [item.loc];
                            }
                        });
                    });
                    
                    let locVal = ""; // Removed from DOM.
                    
                    let totalChecked = 0;
                    ['agi', 'pre', 'box', 'crate', 'other'].forEach(t => {
                        window.globalAwbItems[t].forEach(item => { totalChecked += item.qty; });
                    });

                    // Si hay algún valor numérico ingresado pero no lo agregaron con el +, auto-agregarlo para evitar que se pierdan datos
                    ['agi', 'pre', 'box', 'crate', 'other'].forEach(type => {
                        const val = parseInt(document.getElementById('g-awb-' + type).value, 10);
                        if (!isNaN(val) && val > 0) {
                            if (type === 'agi') {
                                agiArr.push(val);
                                itemLocations[`agi-${agiArr.length - 1}`] = [];
                            }
                            if (type === 'pre') {
                                preArr.push(val);
                                itemLocations[`pre-${preArr.length - 1}`] = [];
                            }
                            if (type === 'box') {
                                boxArr.push(val);
                                itemLocations[`box-${boxArr.length - 1}`] = [];
                            }
                            if (type === 'crate') {
                                crtArr.push(val);
                                itemLocations[`crate-${crtArr.length - 1}`] = [];
                            }
                            if (type === 'other') {
                                othArr.push(val);
                                itemLocations[`other-${othArr.length - 1}`] = [];
                            }
                            totalChecked += val;
                        }
                    });

                    if(!number) {
                        window.showValidationModal("Missing Information", "AWB Number is required.");
                        return;
                    }
                    if(!tot) {
                        window.showValidationModal("Missing Information", "Total Pieces is required.");
                        return;
                    }

                    const houseArr = hou ? hou.split(',').map(s=>s.trim()).filter(s=>s) : [];

                    const newAwbItem = {
                        pieces: pcs || 0,
                        weight: wgt || null,
                        hasHouse: houseArr.length > 0,
                        house_number: houseArr,
                        remarks: rem || null,
                        splitNumber: 1,
                        isSplit: false,
                        refCarrier,
                        refNumber,
                        refULD: uld || null,
                        refDate: refDate || document.getElementById('g-awb-date')?.value || null
                    };

                    const { data: existingAwb, error: fetchErr } = await supabaseClient
                        .from('AWB')
                        .select('*')
                        .eq('AWB number', number)
                        .maybeSingle();

                    let currentDataAWB = [];
                    let currentDataCoord = [];
                    let currentDataLocation = [];
                    let isUpdate = false;

                    if (!fetchErr && existingAwb) {
                        isUpdate = true;
                        if (Array.isArray(existingAwb['data-AWB'])) {
                            currentDataAWB = existingAwb['data-AWB'];
                        } else if (existingAwb['data-AWB']) {
                            try { currentDataAWB = JSON.parse(existingAwb['data-AWB']); } catch(e) {}
                        }

                        if (Array.isArray(existingAwb['data-coordinator'])) {
                            currentDataCoord = existingAwb['data-coordinator'];
                        } else if (existingAwb['data-coordinator']) {
                            try { currentDataCoord = JSON.parse(existingAwb['data-coordinator']); } catch(e) {}
                        }

                        if (Array.isArray(existingAwb['data-location'])) {
                            currentDataLocation = existingAwb['data-location'];
                        } else if (existingAwb['data-location']) {
                            try { currentDataLocation = JSON.parse(existingAwb['data-location']); } catch(e) {}
                        }
                    }

                    const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                    const existingAwbIdx = currentDataAWB.findIndex(item => 
                        eqRef(item.refCarrier, refCarrier) &&
                        eqRef(item.refNumber, refNumber) &&
                        eqRef(item.refDate, newAwbItem.refDate) &&
                        eqRef(item.refULD, uld)
                    );

                    if (existingAwbIdx >= 0) {
                        currentDataAWB[existingAwbIdx] = newAwbItem;
                    } else {
                        currentDataAWB.push(newAwbItem);
                    }

                    if (totalChecked > 0 || locVal) {
                        const coordEntry = {
                            awbNumber: number,
                            refCarrier,
                            refNumber,
                            refDate: refDate || document.getElementById('g-awb-date')?.value || null,
                            refULD: uld || null,
                            "Agi skid": agiArr,
                            "Pre skid": preArr,
                            "Crates": crtArr,
                            "Box": boxArr,
                            "Other": othArr,
                            "Location required": locVal,
                            "Total Checked": totalChecked,
                            "Mismatch Report": "",
                            "itemLocations": itemLocations,
                            "specificLocations": []
                        };

                        const existingCoordIdx = currentDataCoord.findIndex(item => 
                            eqRef(item.refCarrier, refCarrier) &&
                            eqRef(item.refNumber, refNumber) &&
                            eqRef(item.refDate, coordEntry.refDate) &&
                            eqRef(item.refULD, uld)
                        );

                        if (existingCoordIdx >= 0) {
                            currentDataCoord[existingCoordIdx] = coordEntry;
                        } else {
                            currentDataCoord.push(coordEntry);
                        }
                    }

                    let locsMap = { agi: {}, pre: {}, box: {}, crate: {}, other: {} };
                    let hasLocations = !!locVal; // if locval has something
                    ['agi', 'pre', 'box', 'crate', 'other'].forEach(t => {
                        window.globalAwbItems[t].forEach((item, index) => {
                            if (item.loc) {
                                locsMap[t][index] = [item.loc];
                                hasLocations = true;
                            } else {
                                locsMap[t][index] = [];
                            }
                        });
                    });

                    if (hasLocations) {
                        const locEntry = {
                            awbNumber: number,
                            refCarrier,
                            refNumber,
                            refDate: refDate || document.getElementById('g-awb-date')?.value || null,
                            refULD: uld || null,
                            itemLocations: locsMap,
                            "Location required": locVal
                        };

                        const existingLocIdx = currentDataLocation.findIndex(item => 
                            eqRef(item.refCarrier, refCarrier) &&
                            eqRef(item.refNumber, refNumber) &&
                            eqRef(item.refDate, locEntry.refDate) &&
                            eqRef(item.refULD, uld)
                        );

                        if (existingLocIdx >= 0) {
                            currentDataLocation[existingLocIdx] = locEntry;
                        } else {
                            currentDataLocation.push(locEntry);
                        }
                    }

                    if (isUpdate) {
                        const updatePayload = {
                            total: parseInt(tot, 10),
                            "data-AWB": currentDataAWB
                        };
                        if (currentDataCoord.length > 0) {
                            updatePayload["data-coordinator"] = currentDataCoord;
                        }
                        if (currentDataLocation.length > 0) {
                            updatePayload["data-location"] = currentDataLocation;
                        }
                        const updateRes = await supabaseClient.from('AWB').update(updatePayload).eq('AWB number', number);
                        if (updateRes.error) throw updateRes.error;
                    } else {
                        const insertPayload = {
                            "AWB number": number,
                            total: parseInt(tot, 10),
                            "data-AWB": currentDataAWB
                        };
                        if (currentDataCoord.length > 0) {
                            insertPayload["data-coordinator"] = currentDataCoord;
                        }
                        if (currentDataLocation.length > 0) {
                            insertPayload["data-location"] = currentDataLocation;
                        }
                        const insertRes = await supabaseClient.from('AWB').insert([insertPayload]);
                        if (insertRes.error) throw insertRes.error;
                    }

                    // SUCCESS OVERLAY
                    const overlay = document.createElement('div');
                    overlay.style.cssText = `
                        position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                        background: rgba(255, 255, 255, 0.85); z-index: 99999;
                        display: flex; align-items: center; justify-content: center;
                        backdrop-filter: blur(4px); opacity: 0; transition: opacity 0.3s ease;
                    `;
                    overlay.innerHTML = `
                        <div style="background: white; padding: 32px 48px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); display: flex; flex-direction: column; align-items: center; gap: 16px; transform: scale(0.9); transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);">
                            <div style="width: 64px; height: 64px; background: #10b981; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </div>
                            <h2 style="margin: 0; color: #0f172a; font-size: 20px; font-weight: 700;">¡Guardado!</h2>
                            <p style="margin: 0; color: #64748b; font-size: 14px;">El AWB ha sido registrado con éxito.</p>
                        </div>
                    `;
                    document.body.appendChild(overlay);

                    // Animate in
                    requestAnimationFrame(() => {
                        overlay.style.opacity = '1';
                        overlay.firstElementChild.style.transform = 'scale(1)';
                    });

                    addAwbGlobalForm.reset();
                    
                    // Reset global lists
                    window.globalAwbItems = { agi: [], pre: [], crate: [], box: [], other: [] };
                    window.renderGlobalAwbItems();
                    
                    // Trigger reload of the list
                    if (window.fetchGlobalAwbs) window.fetchGlobalAwbs();

                    // Trigger "Back" button
                    const backAwbBtn = document.getElementById('back-to-awbs-btn');
                    if(backAwbBtn) backAwbBtn.click();
                    
                    // Remove overlay after delay
                    setTimeout(() => {
                        overlay.style.opacity = '0';
                        overlay.firstElementChild.style.transform = 'scale(0.9)';
                        setTimeout(() => overlay.remove(), 300);
                    }, 1500);
                    
                } catch (err) {
                    console.error("Error guardando AWB:", err);
                    window.showValidationModal("Error Saving AWB", err.message || "An unexpected error occurred.");
                } finally {
                    saveBtn.textContent = originalBtnText;
                    saveBtn.disabled = false;
                }
            });
        }

        // ------ NUEVA LÓGICA LOCAL ULD + AWBs ------
        let localNewUldAwbs = [];
        
        function renderLocalNewUldAwbs() {
            const tableBody = document.getElementById('g-local-awb-table-body');
            
            if (!tableBody) return;
            
            if (localNewUldAwbs.length === 0) {
                tableBody.innerHTML = '<tr style="display: table; width: 100%; table-layout: fixed;"><td colspan="7" style="padding: 16px; text-align: center; color: #94a3b8; font-size: 13px;">No AWBs added yet.</td></tr>';
                return;
            }

            tableBody.innerHTML = '';
            localNewUldAwbs.forEach((awb, index) => {
                const tr = document.createElement('tr');
                tr.style.cssText = 'display: table; width: 100%; table-layout: fixed; border-bottom: 1px solid #f1f5f9;';

                const houseCount = awb.house ? awb.house.split(',').filter(h => h.trim().length > 0).length : 0;
                
                const houseStrSafe = (awb.house || '').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                const houseDisplay = houseCount > 0 
                    ? `<div onclick="showHouseNumbersModal('${houseStrSafe}')" style="display:inline-flex; align-items:center; justify-content:center; width:22px; height:22px; border-radius:50%; background-color:#e0e7ff; color:#4f46e5; font-weight:bold; cursor:pointer;" title="Click to view details">${houseCount}</div>` 
                    : '0';

                tr.innerHTML = `
                    <td style="padding: 10px; font-size: 11px; color: #64748b; font-weight: 600; width: 40px; vertical-align: middle; text-align: center;">${index + 1}</td>
                    <td style="padding: 10px; font-size: 13px; color: #0f172a; font-weight: 600; width: 130px; vertical-align: middle;">${awb.number}</td>
                    <td style="padding: 10px; font-size: 12px; color: #475569; width: 70px; vertical-align: middle;">${awb.pieces || '0'}</td>
                    <td style="padding: 10px; font-size: 12px; color: #475569; width: 70px; vertical-align: middle;">${awb.total || '0'}</td>
                    <td style="padding: 10px; font-size: 12px; color: #475569; width: 80px; vertical-align: middle;">${awb.weight || '0.0'}</td>
                    <td style="padding: 10px; font-size: 12px; color: #475569; width: 120px; vertical-align: middle; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${houseDisplay}</td>
                    <td style="padding: 10px; font-size: 11px; color: #475569; vertical-align: middle; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="${awb.remarks || ''}">${awb.remarks || '-'}</td>
                    <td style="padding: 10px; text-align: right; width: 60px; vertical-align: middle;">
                        <button type="button" onclick="removeLocalNewUldAwb(${index})" style="background: transparent; border: none; color: #ef4444; cursor: pointer;" title="Remove">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                        </button>
                    </td>
                `;
                tableBody.appendChild(tr);
            });
        }

        function updateAddUldAutoSums() {
            const pcsAutoEl = document.getElementById('g-uld-pieces-auto');
            const wgtAutoEl = document.getElementById('g-uld-weight-auto');
            
            if (pcsAutoEl && pcsAutoEl.checked) {
                let totalPcs = localNewUldAwbs.reduce((sum, a) => sum + (parseInt(a.pieces, 10) || 0), 0);
                const pcsField = document.getElementById('g-uld-pieces');
                if (pcsField) pcsField.value = totalPcs > 0 ? totalPcs : '';
            }
            if (wgtAutoEl && wgtAutoEl.checked) {
                let totalWgt = localNewUldAwbs.reduce((sum, a) => sum + (parseFloat(a.weight) || 0), 0);
                const wgtField = document.getElementById('g-uld-weight');
                if (wgtField) wgtField.value = totalWgt > 0 ? parseFloat(totalWgt.toFixed(1)) : '';
            }
        }

        window.removeLocalNewUldAwb = function(index) {
            localNewUldAwbs.splice(index, 1);
            renderLocalNewUldAwbs();
            updateAddUldAutoSums();
        };

        window.showHouseNumbersModal = function(houseStr) {
            const overlay = document.getElementById('house-numbers-overlay');
            const listContainer = document.getElementById('house-numbers-list');
            if (overlay && listContainer) {
                const houses = houseStr ? houseStr.split(',').map(h => h.trim()).filter(h => h.length > 0) : [];
                listContainer.innerHTML = '';
                if (houses.length === 0) {
                    listContainer.innerHTML = '<div style="padding: 10px; text-align: center; color: #94a3b8;">No House Numbers available.</div>';
                } else {
                    houses.forEach((h, idx) => {
                        const itemStr = `<div style="padding: 8px 12px; border-bottom: 1px solid #f1f5f9; background: ${idx % 2 === 0 ? '#fafafa' : '#ffffff'};">${idx + 1}. <span style="font-weight: 600; color: #0f172a;">${h}</span></div>`;
                        listContainer.innerHTML += itemStr;
                    });
                }
                overlay.style.display = 'flex';
            }
        };

        const guldAddAwbBtn = document.getElementById('guld-add-awb-btn');
        if (guldAddAwbBtn) {
            guldAddAwbBtn.addEventListener('click', () => {
                const aNum = document.getElementById('guld-awb-number').value.trim().toUpperCase();
                const aPcs = document.getElementById('guld-awb-pieces').value;
                const aWgt = document.getElementById('guld-awb-weight').value;
                const aTot = document.getElementById('guld-awb-total').value;
                const aHou = document.getElementById('guld-awb-house').value.trim().toUpperCase();
                const aRem = document.getElementById('guld-awb-remarks').value.trim();

                if (!aNum) {
                    window.showValidationModal("Missing Information", "AWB Number is required.");
                    return;
                }

                localNewUldAwbs.push({
                    number: aNum,
                    pieces: aPcs,
                    weight: aWgt,
                    total: aTot,
                    house: aHou,
                    remarks: aRem
                });

                document.getElementById('guld-awb-number').value = '';
                document.getElementById('guld-awb-pieces').value = '';
                document.getElementById('guld-awb-weight').value = '';
                document.getElementById('guld-awb-total').value = '';
                document.getElementById('guld-awb-house').value = '';
                document.getElementById('guld-awb-remarks').value = '';

                renderLocalNewUldAwbs();
                updateAddUldAutoSums();
            });
        }

        const saveNewUldAwbsBtn = document.getElementById('save-new-uld-awbs-btn');
        if (saveNewUldAwbsBtn) {
            saveNewUldAwbsBtn.addEventListener('click', async () => {
                const uNum = document.getElementById('g-uld-number').value.trim().toUpperCase();
                
                if (!uNum) {
                    window.showValidationModal("Missing Information", "ULD Number is required.");
                    return;
                }

                const prevText = saveNewUldAwbsBtn.textContent;
                saveNewUldAwbsBtn.disabled = true;
                saveNewUldAwbsBtn.textContent = 'Guardando...';

                try {
                    // 1. Recoger datos del ULD master local
                    const uFlightCombo = document.getElementById('g-uld-flight').value;
                    let fCarrier = null, fNumber = null, fDate = null;
                    try {
                        const parsed = JSON.parse(uFlightCombo);
                        fCarrier = parsed.carrier; fNumber = parsed.number; fDate = parsed.date;
                    } catch(e) {}

                    const uPcs = document.getElementById('g-uld-pieces').value;
                    const uWgt = document.getElementById('g-uld-weight').value;
                    const uRem = document.getElementById('g-uld-remarks').value;
                    const uStatus = document.getElementById('g-uld-status') ? document.getElementById('g-uld-status').value : 'waiting';
                    const uPrio = document.getElementById('g-uld-priority').checked;
                    const uBrk = document.getElementById('g-uld-break').checked;
                    const isPiecesAuto = document.getElementById('g-uld-pieces-auto') ? document.getElementById('g-uld-pieces-auto').checked : false;
                    const isWeightAuto = document.getElementById('g-uld-weight-auto') ? document.getElementById('g-uld-weight-auto').checked : false;

                    const uldPayload = {
                        "ULD number": uNum,
                        refCarrier: fCarrier,
                        refNumber: fNumber,
                        refDate: fDate,
                        pieces: uPcs ? parseInt(uPcs, 10) : 0,
                        weight: uWgt ? parseFloat(uWgt) : 0,
                        remarks: uRem || null,
                        isPriority: uPrio,
                        isBreak: uBrk,
                        status: uStatus || 'waiting'
                    };

                    // 2. Guardar el ULD local
                    const uldRes = await supabaseClient.from('ULD').insert([uldPayload]).select('*').single();
                    if (uldRes.error) {
                        throw new Error(`Error en ULD ${uNum}: ${uldRes.error.message || uldRes.error.hint}`);
                    }
                    
                    const savedUldId = uldRes.data.id;

                    // 3. Guardar TODOS los AWBs vinculándolos a este ULD en paralelo (Mapeado a data-AWB para consistencia global)
                    if (localNewUldAwbs.length > 0) {
                        const awbInsertPromises = localNewUldAwbs.map(async awb => {
                            try {
                                const { data: existingAwb, error: fetchErr } = await supabaseClient
                                    .from('AWB')
                                    .select('*')
                                    .eq('AWB number', awb.number)
                                    .maybeSingle();
                                
                                let currentDataAWB = [];
                                let isUpdate = false;

                                if (!fetchErr && existingAwb) {
                                    isUpdate = true;
                                    if (Array.isArray(existingAwb['data-AWB'])) {
                                        currentDataAWB = existingAwb['data-AWB'];
                                    } else if (existingAwb['data-AWB']) {
                                        try { currentDataAWB = JSON.parse(existingAwb['data-AWB']); } catch(e) {}
                                    }
                                }

                                const houseArray = awb.house ? awb.house.split(',').map(h => h.trim()).filter(h => h.length > 0) : [];
                                
                                const newAwbItem = {
                                    refCarrier: fCarrier,
                                    refNumber: fNumber,
                                    refDate: fDate,
                                    refULD: uNum,
                                    pieces: awb.pieces ? parseInt(awb.pieces, 10) : 0,
                                    weight: awb.weight ? parseFloat(awb.weight) : 0,
                                    remarks: awb.remarks || null,
                                    isBreak: uBrk,
                                    house_number: houseArray
                                };

                                const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                                const existingIdx = currentDataAWB.findIndex(item => 
                                    eqRef(item.refCarrier, fCarrier) &&
                                    eqRef(item.refNumber, fNumber) &&
                                    eqRef(item.refDate, fDate) &&
                                    eqRef(item.refULD, uNum)
                                );

                                if (existingIdx >= 0) {
                                    currentDataAWB[existingIdx] = newAwbItem;
                                } else {
                                    currentDataAWB.push(newAwbItem);
                                }

                                if (isUpdate) {
                                    return supabaseClient.from('AWB')
                                        .update({
                                            "total": parseInt(awb.total, 10) || 0,
                                            "data-AWB": currentDataAWB
                                        })
                                        .eq('AWB number', awb.number);
                                } else {
                                    const insertPayload = {
                                        "AWB number": awb.number,
                                        "total": parseInt(awb.total, 10) || 0,
                                        "data-AWB": currentDataAWB
                                    };
                                    return supabaseClient.from('AWB').insert([insertPayload]);
                                }
                            } catch (e) {
                                return { error: { message: e.message } };
                            }
                        });

                        const awbResults = await Promise.all(awbInsertPromises);
                        
                        awbResults.forEach((res, idx) => {
                            if (res && res.error) {
                                console.error(`Error guardando AWB ${localNewUldAwbs[idx].number}:`, res.error);
                            }
                        });
                    }

                    // SUCCESS OVERLAY
                    const overlay = document.createElement('div');
                    overlay.style.cssText = `
                        position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                        background: rgba(255, 255, 255, 0.85); z-index: 99999;
                        display: flex; align-items: center; justify-content: center;
                        backdrop-filter: blur(4px); opacity: 0; transition: opacity 0.3s ease;
                    `;
                    overlay.innerHTML = `
                        <div style="background: white; padding: 32px 48px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); display: flex; flex-direction: column; align-items: center; gap: 16px; transform: scale(0.9); transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);">
                            <div style="width: 64px; height: 64px; background: #10b981; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </div>
                            <h2 style="margin: 0; color: #0f172a; font-size: 20px; font-weight: 700;">¡Guardado!</h2>
                            <p style="margin: 0; color: #64748b; font-size: 14px;">Los contenedores ULD han sido registrados con éxito.</p>
                        </div>
                    `;
                    document.body.appendChild(overlay);

                    // Animate in
                    requestAnimationFrame(() => {
                        overlay.style.opacity = '1';
                        overlay.firstElementChild.style.transform = 'scale(1)';
                    });

                    // Reset
                    localNewUldAwbs = [];
                    renderLocalNewUldAwbs();
                    if(document.getElementById('add-uld-global-form')) document.getElementById('add-uld-global-form').reset();
                    fetchGlobalUlds(); // Actualiza la lista principal
                    
                    // Remove overlay slowly
                    setTimeout(() => {
                        overlay.style.opacity = '0';
                        overlay.firstElementChild.style.transform = 'scale(0.9)';
                        setTimeout(() => {
                            overlay.remove();
                            const backBtn = document.getElementById('back-to-ulds-btn');
                            if(backBtn) backBtn.click();
                        }, 300);
                    }, 1500);

                } catch (err) {
                    console.error(err);
                    window.showValidationModal("Error", "Hubo un error al guardar: " + err.message);
                } finally {
                    saveNewUldAwbsBtn.disabled = false;
                    saveNewUldAwbsBtn.textContent = 'Save ULD & AWBs';
                }
            });
        }

        const cancelAddNewUldBtn = document.getElementById('cancel-add-uld-btn');
        if (cancelAddNewUldBtn && document.getElementById('back-to-ulds-btn')) {
            cancelAddNewUldBtn.addEventListener('click', () => {
                document.getElementById('back-to-ulds-btn').click();
            });
        }

        // Llamar a la carga de Vuelos al Select y a los ULDs Globales iniciales
        populateFlightDropdownForUld();
        fetchGlobalUlds();
        
        // ---------- FIN LÓGICA DE ULD (GLOBAL) ----------

        // ---------- LÓGICA DE AWB (GLOBAL) ----------
        const globalAwbTableBody = document.getElementById('global-awb-table-body');
        const awbSearchMain = document.getElementById('awb-search-main');

        let allLoadedAwbs = []; 

        if (awbSearchMain && globalAwbTableBody) {
            awbSearchMain.addEventListener('keyup', function() {
                const term = this.value.toLowerCase();
                const rows = globalAwbTableBody.querySelectorAll('tr');
                rows.forEach(row => {
                    if (row.querySelector('.loading-td')) return;
                    const text = row.textContent.toLowerCase();
                    row.style.display = text.includes(term) ? '' : 'none';
                });
            });
        }

        window.fetchGlobalAwbs = async function fetchGlobalAwbs() {
            if (!globalAwbTableBody) return;
            try {
                let awbRes = await supabaseClient.from('AWB').select('*');

                if (awbRes.error) {
                    console.error("Error al obtener AWBs:", awbRes.error);
                    globalAwbTableBody.innerHTML = '<tr><td colspan="3" style="text-align:center; padding: 16px;">Error al cargar listado de AWBs.</td></tr>';
                    return;
                }

                allLoadedAwbs = awbRes.data || [];
                globalAwbTableBody.innerHTML = '';

                if (allLoadedAwbs.length === 0) {
                    globalAwbTableBody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 20px; color: #94a3b8;">No AWBs available.</td></tr>';
                    return;
                }

                allLoadedAwbs.sort((a, b) => {
                    const numA = (a['AWB number'] || a.awb_number || '').toString();
                    const numB = (b['AWB number'] || b.awb_number || '').toString();
                    return numA.localeCompare(numB);
                });

                allLoadedAwbs.forEach((awb, index) => {
                    const tr = document.createElement('tr');
                    tr.style.cursor = 'pointer';
                    
                    const aNumber = awb['AWB number'] || awb.awb_number || '-';
                    const expectedTotal = parseInt(awb.total || 0, 10);

                    let receivedPcs = 0;
                    let mismatchReportsText = [];
                    
                    if (awb['data-coordinator'] && Array.isArray(awb['data-coordinator'])) {
                        const coordArr = awb['data-coordinator'];
                        receivedPcs = coordArr.reduce((acc, curr) => acc + (parseInt(curr['Total Checked']) || 0), 0);
                        coordArr.forEach(curr => {
                            if (curr['Mismatch Report'] && curr['Mismatch Report'].trim() !== '') {
                                mismatchReportsText.push(curr['Mismatch Report'].trim());
                            }
                        });
                    } else if (awb['data-coordinator']) {
                        try {
                            const parsed = JSON.parse(awb['data-coordinator']);
                            if (Array.isArray(parsed)) {
                                receivedPcs = parsed.reduce((acc, curr) => acc + (parseInt(curr['Total Checked']) || 0), 0);
                                parsed.forEach(curr => {
                                    if (curr['Mismatch Report'] && curr['Mismatch Report'].trim() !== '') {
                                        mismatchReportsText.push(curr['Mismatch Report'].trim());
                                    }
                                });
                            }
                        } catch(e) {}
                    }

                    tr.addEventListener('click', () => {
                        window.openAwbInfoDrawer(aNumber, expectedTotal, awb);
                    });
                    
                    const isReady = (expectedTotal > 0 && receivedPcs === expectedTotal);
                    const statusHtml = isReady 
                        ? '<div style="display:inline-flex; align-items:center; justify-content:center; background:#dcfce7; color:#166534; padding:4px 8px; border-radius:6px; font-size:11px; font-weight:700; min-width:64px;">READY</div>' 
                        : '<div style="display:inline-flex; align-items:center; justify-content:center; background:#fef3c7; color:#b45309; padding:4px 8px; border-radius:6px; font-size:11px; font-weight:700; min-width:64px;">PENDING</div>';

                    let mismatchHtml = '-';
                    if (mismatchReportsText.length > 0) {
                        const formattedReports = mismatchReportsText.map((req, i) => `<b>Report ${i + 1}:</b><br>${req}`).join('<br><br>');
                        const safeReport = formattedReports.replace(/'/g, "\\'").replace(/"/g, '&quot;').replace(/\n/g, '<br>');

                        mismatchHtml = `<div title="Click to view Report" 
                            style="display:inline-flex; align-items:center; justify-content:center; background:#fee2e2; color:#b91c1c; width:22px; height:22px; border-radius:50%; font-size:11px; font-weight:bold; cursor:pointer;" 
                            onclick="event.stopPropagation(); window.viewMismatchReport('${safeReport}')">
                            ${mismatchReportsText.length}
                        </div>`;
                    }

                    tr.innerHTML = `
                        <td style="text-align: center; color: #94a3b8; font-weight: 500;">${index + 1}</td>
                        <td style="font-weight: 600; color: #334155; white-space: nowrap;">${aNumber}</td>
                        <td style="text-align: center;">${mismatchHtml}</td>
                        <td style="color: #0d9488; font-weight: 500; text-align: center;">${receivedPcs} <span style="font-size: 11px; color:#cbd5e1;">pcs</span></td>
                        <td style="color: #64748b; text-align: center;">${expectedTotal}</td>
                        <td style="text-align: center;">${statusHtml}</td>
                    `;
                    globalAwbTableBody.appendChild(tr);
                });

            } catch (err) {
                globalAwbTableBody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 16px; color:#ef4444;">Error cargando AWBs.</td></tr>';
            }
        }

        const awbInfoDrawer = document.getElementById('awb-info-drawer');
        const awbInfoOverlay = document.getElementById('awb-info-drawer-overlay');
        const closeAwbInfoBtn = document.getElementById('close-awb-info-drawer-btn');
        
        window.openAwbInfoDrawer = function(awbNum, total, awbRow) {
            document.getElementById('info-drawer-awb-title').textContent = `AWB: ${awbNum}`;
            document.getElementById('info-drawer-awb-total').textContent = total || '0';
            
            const listContainer = document.getElementById('info-drawer-awb-list');
            listContainer.innerHTML = '';

            const dataAwb = awbRow ? awbRow['data-AWB'] : null;
            let splits = [];
            if (Array.isArray(dataAwb)) splits = dataAwb;
            else if (dataAwb) {
                try { splits = JSON.parse(dataAwb); } catch(e){}
            }

            // Parse locations data
            let locList = [];
            if (awbRow && awbRow['data-location']) {
                if (Array.isArray(awbRow['data-location'])) locList = awbRow['data-location'];
                else {
                    try { locList = JSON.parse(awbRow['data-location']); } catch(e){}
                }
            }
            if (!Array.isArray(locList)) locList = [];

            // Parse coordinator data
            let coordList = [];
            if (awbRow && awbRow['data-coordinator']) {
                if (Array.isArray(awbRow['data-coordinator'])) coordList = awbRow['data-coordinator'];
                else {
                    try { coordList = JSON.parse(awbRow['data-coordinator']); } catch(e){}
                }
            }
            if (!Array.isArray(coordList)) coordList = [];
            
            const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
            const eqNum = (a, b) => {
                let nA = String(a || '').trim().toLowerCase().replace(/^0+/, '');
                let nB = String(b || '').trim().toLowerCase().replace(/^0+/, '');
                if (!nA) nA = '0';
                if (!nB) nB = '0';
                return nA === nB;
            };
            let allShipments = [];

            splits.forEach(s => {
                allShipments.push({
                    hasSplit: true,
                    splitData: s,
                    refCarrier: s.refCarrier,
                    refNumber: s.refNumber,
                    refDate: s.refDate,
                    refULD: s.refULD
                });
            });

            if (coordList && coordList.length) {
                coordList.forEach(c => {
                    let existing = allShipments.find(s => 
                        eqRef(s.refCarrier, c.refCarrier) &&
                        eqNum(s.refNumber, c.refNumber) &&
                        eqRef(s.refDate, c.refDate) &&
                        eqRef(s.refULD, c.refULD)
                    );
                    
                    if (!existing) existing = allShipments.find(s => eqRef(s.refCarrier, c.refCarrier) && eqNum(s.refNumber, c.refNumber) && eqRef(s.refULD, c.refULD));
                    if (!existing) existing = allShipments.find(s => eqRef(s.refCarrier, c.refCarrier) && eqNum(s.refNumber, c.refNumber));
                    if (!existing && allShipments.length === 1) existing = allShipments[0];

                    if (existing) { existing.hasCoord = true; existing.coordData = c; }
                    else {
                        allShipments.push({ hasSplit: false, hasCoord: true, coordData: c, refCarrier: c.refCarrier, refNumber: c.refNumber, refDate: c.refDate, refULD: c.refULD });
                    }
                });
            }

            if (locList && locList.length) {
                locList.forEach(l => {
                    let existing = allShipments.find(s => 
                        eqRef(s.refCarrier, l.refCarrier) &&
                        eqNum(s.refNumber, l.refNumber) &&
                        eqRef(s.refDate, l.refDate) &&
                        eqRef(s.refULD, l.refULD)
                    );
                    
                    if (!existing) existing = allShipments.find(s => eqRef(s.refCarrier, l.refCarrier) && eqNum(s.refNumber, l.refNumber) && eqRef(s.refULD, l.refULD));
                    if (!existing) existing = allShipments.find(s => eqRef(s.refCarrier, l.refCarrier) && eqNum(s.refNumber, l.refNumber));
                    if (!existing && allShipments.length === 1) existing = allShipments[0];

                    if (existing) { existing.hasLoc = true; existing.locData = l; }
                    else {
                        allShipments.push({ hasSplit: false, hasLoc: true, locData: l, refCarrier: l.refCarrier, refNumber: l.refNumber, refDate: l.refDate, refULD: l.refULD });
                    }
                });
            }

            if (allShipments.length === 0) {
                listContainer.innerHTML = '<div style="padding: 16px; text-align: center; color: #94a3b8; font-size: 13px; font-style: italic;">No shipment data logged yet.</div>';
            } else {
                allShipments.forEach(ship => {
                    const card = document.createElement('div');
                    card.style.cssText = 'background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; display: flex; flex-direction: column; gap: 16px; margin-bottom: 8px;';

                    const split = ship.splitData || {};
                    const fRef = (ship.refCarrier && ship.refNumber) ? `${ship.refCarrier} ${ship.refNumber}` : (ship.refFlight || '-');
                    const hList = split.house_number || [];
                    const hStr = hList.length > 0 ? hList.join(', ') : 'None';
                    
                    // Evaluate Coordinator Logic
                    let existingCoordObj = ship.coordData;
                    let coordDetailsHtml = '<span style="color:#94a3b8; font-size:12px; font-style:italic;">No check info</span>';
                    let totalChecked = 0;

                    if (existingCoordObj) {
                        totalChecked = existingCoordObj['Total Checked'] || 0;
                        let coordChips = [];

                        const addGroup = (arr, label) => {
                            let _arr = Array.isArray(arr) ? arr : [arr];
                            let validItems = [];
                            
                            // Only include elements strictly greater than 0
                            _arr.forEach((qty, idx) => {
                                let num = Number(qty || 0);
                                if (num > 0) validItems.push({num, idx});
                            });
                            
                            if (validItems.length === 0) return; // Skip if all 0
                            
                            let groupHtml = `<div style="background: white; border: 1px solid #e7e5e4; border-radius: 6px; padding: 10px; flex: 1; min-width: 100px;">`;
                            groupHtml += `<div style="color: #44403c; font-weight: 700; font-size: 13px; text-transform: uppercase;">${validItems.length} ${label}</div>`;
                            
                            groupHtml += `<div style="display:flex; flex-direction:column; gap:4px; margin-top:8px;">`;
                            validItems.forEach((item, innerIdx) => {
                                groupHtml += `<div style="display:flex; justify-content:space-between; align-items:center; background: #fafaf9; padding: 4px 8px; border-radius:4px; border: 1px solid #e7e5e4;">
                                    <span style="font-size:11px; color:#57534e; font-weight:600;">#${innerIdx + 1}</span>
                                    <span style="font-size:12px; font-weight:700; color:#0f172a;">${item.num} pcs</span>
                                </div>`;
                            });
                            groupHtml += `</div>`;
                            
                            groupHtml += `</div>`;
                            coordChips.push(groupHtml);
                        };

                        addGroup(existingCoordObj['Agi skid'], 'Agi Skid');
                        addGroup(existingCoordObj['Pre skid'], 'Pre Skid');
                        addGroup(existingCoordObj['Crates'], 'Crates');
                        addGroup(existingCoordObj['Box'], 'Boxes');
                        addGroup(existingCoordObj['Other'], 'Other');

                        if (coordChips.length === 0) {
                            coordChips.push('<span style="color:#a8a29e; font-size:11px; font-style:italic;">No logged items > 0</span>');
                        }

                        let mismatch = existingCoordObj['Mismatch Report'] || '';
                        let locReq = existingCoordObj['Location required'] || '';
                        
                        coordDetailsHtml = `
                            <div style="display:flex; flex-wrap:wrap; gap:4px; margin-top:8px;">${coordChips.join('')}</div>
                            <div style="margin-top: 8px; font-size: 11px; display: flex; align-items: center; gap: 8px;">
                                <span style="color:#57534e; font-weight:600;">Location Required?</span>
                                <span style="${locReq === 'true' || locReq === true || String(locReq).toLowerCase() === 'yes' ? 'color:#059669; font-weight:700;' : 'color:#9ca3af;'}">${String(locReq).toUpperCase() || 'NO'}</span>
                            </div>
                            ${mismatch ? `<div style="margin-top: 8px; font-size: 11px; color: #b45309; background: #fffbeb; padding: 6px 8px; border-radius: 4px; border: 1px dashed #fde68a;"><strong>Mismatch Report:</strong> <br> ${mismatch}</div>` : ''}
                        `;
                    }

                    // Evaluate Location Logic
                    let existingLocObj = ship.locData;
                    let locDetailsHtml = '<span style="color:#94a3b8; font-size:12px; font-style:italic;">No locs</span>';
                    
                    if (existingLocObj && existingLocObj.itemLocations) {
                        let catHtmls = [];
                        Object.entries(existingLocObj.itemLocations).forEach(([cat, items]) => {
                            if (items) {
                                Object.entries(items).forEach(([idx, locArr]) => {
                                    if (Array.isArray(locArr) && locArr.length > 0) {
                                        catHtmls.push(`<div style="font-size: 11px; background: white; padding: 6px 8px; border-radius: 4px; border: 1px solid #bbf7d0; display: inline-block; margin: 2px;">
                                            <span style="color:#166534; font-weight: 700; text-transform: capitalize;">${cat} #${Number(idx)+1} :</span> 
                                            <span style="color:#14532d; font-weight: 600; margin-left: 4px;">${locArr.join(' &bull; ')}</span>
                                        </div>`);
                                    }
                                });
                            }
                        });
                        if (catHtmls.length > 0) {
                            locDetailsHtml = `<div style="display:flex; flex-wrap:wrap; gap:4px; margin-top:8px;">${catHtmls.join('')}</div>`;
                        } else {
                            if (existingLocObj.specificLocations && existingLocObj.specificLocations.length > 0) {
                                locDetailsHtml = `<div style="display:flex; flex-wrap:wrap; gap:4px; margin-top:8px;">${existingLocObj.specificLocations.map(l => `<span style="font-size:11px; font-weight: 600; background:white; padding:4px 8px; border-radius:4px; border:1px solid #bbf7d0; color:#166534;">${l}</span>`).join('')}</div>`;
                            }
                        }
                    }

                    const isOrphanedStr = (!ship.hasSplit) ? `<span style="font-size: 10px; background: #ef4444; color: white; padding: 2px 6px; border-radius: 12px; font-weight: 700;">ORPHANED DATA</span>` : '';
                    
                    const isUldBreak = split.isBreak === true || String(split.isBreak).toLowerCase() === 'true' || split.break === true || String(split.break).toLowerCase() === 'true';
                    const breakBadge = isUldBreak ? '<span style="background: #dcfce7; color: #166534; padding: 2px 8px; border-radius: 12px; font-weight: 700; font-size: 10px; border: 1px solid #bbf7d0;">BREAK</span>' : '<span style="background: #fee2e2; color: #991b1b; padding: 2px 8px; border-radius: 12px; font-weight: 700; font-size: 10px; border: 1px solid #fecaca;">NO-BREAK</span>';

                    card.innerHTML = `
                        <!-- Data AWB Summary -->
                        <div style="display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 1px solid #f1f5f9; padding-bottom: 12px;">
                            <div style="display: flex; flex-direction: column; gap: 4px;">
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <span style="font-size: 15px; font-weight: 700; color: #0f172a;">Flight: ${fRef}</span>
                                    <span style="font-size: 11px; background: #e0e7ff; color: #4338ca; padding: 2px 8px; border-radius: 12px; font-weight: 600;">Arrived: ${ship.refDate || 'N/A'}</span>
                                    ${isOrphanedStr}
                                </div>
                                <div style="display: flex; align-items: center; gap: 8px;">
                                    <span style="font-size: 13px; color: #475569; font-weight: 600;">ULD: <span style="color:#0f172a; font-family: monospace; font-size: 14px;">${ship.refULD || '-'}</span></span>
                                    ${breakBadge}
                                </div>
                            </div>
                            <div style="display: flex; gap: 16px; text-align: right; background: #f8fafc; padding: 8px 12px; border-radius: 6px; border: 1px solid #e2e8f0;">
                                <div style="display: flex; flex-direction: column;">
                                    <span style="font-size: 10px; color: #64748b; text-transform: uppercase; font-weight: 700; letter-spacing: 0.5px;">Declared</span>
                                    <span style="font-size: 15px; font-weight: 700; color: #0f172a;">${split.pieces || 0} <span style="font-size: 10px; font-weight:500;">pcs</span> / ${split.weight || 0} <span style="font-size:10px; font-weight:500;">kg</span></span>
                                </div>
                                <div style="width: 1px; background: #e2e8f0;"></div>
                                <div style="display: flex; flex-direction: column;">
                                    <span style="font-size: 10px; color: #64748b; text-transform: uppercase; font-weight: 700; letter-spacing: 0.5px;">Checked</span>
                                    <span style="font-size: 15px; font-weight: 700; color: ${totalChecked >= (split.pieces||0) ? '#059669' : '#d97706'};">${totalChecked} <span style="font-size: 10px; font-weight:500;">pcs</span></span>
                                </div>
                            </div>
                        </div>

                        <!-- Data Coordinator & Location Breakdowns -->
                        ${isUldBreak ? `
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                            <!-- Coordinator -->
                            <div style="background: #fafaf9; border: 1px solid #e7e5e4; border-radius: 6px; padding: 12px; box-shadow: 0 1px 2px rgba(0,0,0,0.05);">
                                <h5 style="margin: 0; font-size: 11px; color: #57534e; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;"><i class="fas fa-clipboard-check"></i> Data Coordinator</h5>
                                ${existingCoordObj ? `<div style="font-size: 10px; color: #78716c; margin-top: 4px; margin-bottom: 8px; font-weight: 600;"><i class="fas fa-user-check"></i> ${existingCoordObj.checkedBy || 'Unknown User'} &bull; ${existingCoordObj.checkedAt ? new Date(existingCoordObj.checkedAt).toLocaleString() : 'Unknown Time'}</div>` : ''}
                                ${coordDetailsHtml}
                            </div>
                            
                            <!-- Location -->
                            <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 6px; padding: 12px; box-shadow: 0 1px 2px rgba(0,0,0,0.05);">
                                <h5 style="margin: 0; font-size: 11px; color: #166534; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px;"><i class="fas fa-map-marker-alt"></i> Data Location</h5>
                                ${existingLocObj ? `<div style="font-size: 10px; color: #15803d; margin-top: 4px; margin-bottom: 8px; font-weight: 600;"><i class="fas fa-user-edit"></i> ${existingLocObj.checkedBy || 'Unknown User'} &bull; ${existingLocObj.checkedAt ? new Date(existingLocObj.checkedAt).toLocaleString() : 'Unknown Time'}</div>` : ''}
                                ${locDetailsHtml}
                            </div>
                        </div>
                        ` : ''}

                        <!-- Houses & Remarks -->
                        <div style="display: flex; flex-direction: column; gap: 6px; background: #f8fafc; padding: 10px; border-radius: 6px; border: 1px dashed #cbd5e1;">
                            <div style="font-size: 12px; display: flex; gap: 8px;">
                                <span style="color:#64748b; font-weight: 600; width: 60px;">Houses:</span> <span style="color:#334155;">${hStr}</span>
                            </div>
                            <div style="font-size: 12px; display: flex; gap: 8px;">
                                <span style="color:#64748b; font-weight: 600; width: 60px;">Remarks:</span> <span style="color:#334155; font-style: ${split.remarks ? 'normal' : 'italic'};">${split.remarks || 'No remarks added.'}</span>
                            </div>
                        </div>
                    `;
                    listContainer.appendChild(card);
                });
            }

            if (awbInfoDrawer) awbInfoDrawer.style.right = '0';
            if (awbInfoOverlay) awbInfoOverlay.classList.add('open');
        };

        function closeAwbInfoDrawer() {
            if (awbInfoDrawer) awbInfoDrawer.style.right = '-800px';
            if (awbInfoOverlay) awbInfoOverlay.classList.remove('open');
        }

        if (closeAwbInfoBtn) closeAwbInfoBtn.addEventListener('click', closeAwbInfoDrawer);
        if (awbInfoOverlay) awbInfoOverlay.addEventListener('click', closeAwbInfoDrawer);
        
        fetchGlobalAwbs();
        // ---------- FIN LÓGICA DE AWB (GLOBAL) ----------

        fetchUsers();
    }

    // ==========================================
    // ------- SYSTEM WORKFLOW LOGIC (DUAL) -----
    // ==========================================
    
    // Panel Left
    const sysDateLeft = document.getElementById('sys-date-left');
    const sysFlightsLeft = document.getElementById('sys-flights-left');
    const sysUldsLeft = document.getElementById('sys-ulds-left');
    const sysReceiveBtnLeft = document.getElementById('sys-receive-btn-left');
    
    // Panel Right
    const sysDateRight = document.getElementById('sys-date-right');
    const sysFlightsRight = document.getElementById('sys-flights-right');
    const sysUldsRight = document.getElementById('sys-ulds-right');
    const sysReceiveBtnRight = document.getElementById('sys-receive-btn-right');

    // Función que carga los vuelos dada una fecha y pinta los ChoiceChips en un contenedor
    async function loadFlightsForSystem(dateString, chipsContainer, tableBody, receiveBtn) {
        if (receiveBtn) {
            receiveBtn.disabled = true;
            receiveBtn.style.opacity = '0.5';
            receiveBtn.style.cursor = 'not-allowed';
            receiveBtn.textContent = 'Mark Flight as Received';
            receiveBtn.style.background = '#10b981';
            receiveBtn.onclick = null;
        }

        const colSpan = (tableBody.id === 'coord-ulds') ? 5 : 6;

        if (!dateString) {
            chipsContainer.innerHTML = '<span style="font-size: 13px; color: #94a3b8; font-style: italic;">Pick a date to load flights...</span>';
            tableBody.innerHTML = `<tr><td colspan="${colSpan}" style="text-align: center; padding: 24px 20px; color: #94a3b8; font-size: 13px; border:none; background: transparent;">Select a flight to view ULDs</td></tr>`;
            return;
        }

        chipsContainer.innerHTML = '<span style="font-size: 13px; color: #64748b;">Loading flights...</span>';
        tableBody.innerHTML = `<tr><td colspan="${colSpan}" style="text-align: center; padding: 24px 20px; color: #94a3b8; font-size: 13px; border:none; background: transparent;">Select a flight to view ULDs</td></tr>`;

        // Convertir la fecha local del picker (YYYY-MM-DD)
        let { data: flights, error } = await supabaseClient
            .from('Flight')
            .select('*')
            .eq('date-arrived', dateString);
            
        // Fallback en caso de que la tabla sea 'flights' en minuscula o el nombre de columna sea distinto
        if (error) {
            console.log("Error consultando 'Flight' con 'date-arrived', intentando variaciones...");
            const fallback = await supabaseClient
                .from('flights')
                .select('*')
                .eq('date-arrived', dateString);
            
            error = fallback.error;
            flights = fallback.data;
        }

        if (error || !flights || flights.length === 0) {
            chipsContainer.innerHTML = '<span style="font-size: 13px; color: #e11d48; background: #ffe4e6; padding: 4px 8px; border-radius: 6px;">No flights found for this date.</span>';
            return;
        }

        if (chipsContainer.id === 'sys-flights-left' || chipsContainer.id === 'sys-flights-right') {
            flights = flights.filter(f => f.status === 'Waiting' || f.status === 'Delayed');
        }

        if (flights.length === 0) {
            chipsContainer.innerHTML = '<span style="font-size: 13px; color: #e11d48; background: #ffe4e6; padding: 4px 8px; border-radius: 6px;">No relevant flights found.</span>';
            return;
        }

        // Excluir de la selección todo vuelo globalmente Chequeado para no listarlos (Solo en System)
        if (chipsContainer.id === 'sys-flights-left' || chipsContainer.id === 'sys-flights-right') {
            flights = flights.filter(f => f.status !== 'Checked' && f.status !== 'Chequeado');
            
            if (flights.length === 0) {
                chipsContainer.innerHTML = '<span style="font-size: 13px; color: #64748b; font-style: italic; background:#f1f5f9; padding: 4px 8px; border-radius: 6px;">All relevant flights for this date are already checked out.</span>';
                return;
            }
        }

        // Para Coordinator: Mostrar todos MENOS los que ya están Checked o Ready
        if (chipsContainer.id === 'coord-flights') {
            flights = flights.filter(f => !['Checked', 'Chequeado', 'Ready', 'Listo'].includes(f.status));

            if (flights.length === 0) {
                chipsContainer.innerHTML = '<span style="font-size: 13px; color: #64748b; font-style: italic; background:#f1f5f9; padding: 4px 8px; border-radius: 6px;">No pending flights available for coordination on this date.</span>';
                return;
            }
        }

        // Para Location: Mostrar todos MENOS los que ya están Ready
        if (chipsContainer.id === 'loc-flights') {
            flights = flights.filter(f => !['Ready', 'Listo'].includes(f.status));

            if (flights.length === 0) {
                chipsContainer.innerHTML = '<span style="font-size: 13px; color: #64748b; font-style: italic; background:#f1f5f9; padding: 4px 8px; border-radius: 6px;">No pending flights to locate on this date.</span>';
                return;
            }
        }

        chipsContainer.innerHTML = ''; // Limpiar
        
        flights.forEach(flight => {
            const chip = document.createElement('div');
            chip.className = 'choice-chip';
            chip.dataset.flightId = flight.id; // added for syncing
            chip.textContent = `${flight.carrier}${flight.number}`;
            
            if (flight.status === 'Checked' || flight.status === 'Chequeado' || flight.status === 'Ready' || flight.status === 'Listo') {
                if (chipsContainer.id !== 'loc-flights' || flight.status === 'Ready' || flight.status === 'Listo') {
                    chip.style.backgroundColor = '#dcfce7';
                    chip.style.color = '#166534';
                    chip.style.borderColor = '#bbf7d0';
                }
            }
            
            // Evento Click en el Chip para cargar ULDs
            chip.addEventListener('click', () => {
                if(chip.classList.contains('selected-other')) return; // Bloquear si está seleccionado del otro lado

                // Quitar clase active a todos
                const allChips = chipsContainer.querySelectorAll('.choice-chip');
                allChips.forEach(c => c.classList.remove('active'));
                
                // Activar este
                chip.classList.add('active');
                
                // Cargar ULDs para este vuelo en su respectiva tabla usando la estructura real de asociación refFlight
                loadUldsForSystem(flight, tableBody, receiveBtn);

                // Sincronizar bloqueo cruzado
                syncSystemChips();
            });
            
            chipsContainer.appendChild(chip);
        });

        // Sync at initialization for active elements cross panel
        syncSystemChips();
    }

    // Function to cross-check choice chips in dual system panel
    function syncSystemChips() {
        const leftChips = document.querySelectorAll('#sys-flights-left .choice-chip');
        const rightChips = document.querySelectorAll('#sys-flights-right .choice-chip');
        
        // Reset styles initially
        leftChips.forEach(c => { c.classList.remove('selected-other'); c.title = ''; });
        rightChips.forEach(c => { c.classList.remove('selected-other'); c.title = ''; });
        
        // Find active in left, disable in right
        const activeLeft = document.querySelector('#sys-flights-left .choice-chip.active');
        if (activeLeft) {
            const matchRight = document.querySelector(`#sys-flights-right .choice-chip[data-flight-id="${activeLeft.dataset.flightId}"]`);
            if (matchRight) {
                matchRight.classList.add('selected-other');
                matchRight.title = 'Current active selection in the left panel.';
            }
        }
        
        // Find active in right, disable in left
        const activeRight = document.querySelector('#sys-flights-right .choice-chip.active');
        if (activeRight) {
            const matchLeft = document.querySelector(`#sys-flights-left .choice-chip[data-flight-id="${activeRight.dataset.flightId}"]`);
            if (matchLeft) {
                matchLeft.classList.add('selected-other');
                matchLeft.title = 'Current active selection in the right panel.';
            }
        }
    }

    // Función que carga los ULDs dado un flightId y los pinta en su respectiva tabla
    async function loadUldsForSystem(flight, tableBody, receiveBtn) {
        const isReceived = flight.status === 'Received';
        const isCoordinator = !receiveBtn && (tableBody.id === 'coord-ulds' || tableBody.id === 'loc-ulds');
        const isSystem = tableBody.id === 'sys-ulds-left' || tableBody.id === 'sys-ulds-right';
        const colSpan = isSystem ? 7 : (tableBody.id === 'coord-ulds' ? 7 : 6);
        
        if (receiveBtn) {
            receiveBtn.disabled = true;
            receiveBtn.style.opacity = isReceived ? '1' : '0.5';
            receiveBtn.style.cursor = isReceived ? 'default' : 'not-allowed';
            receiveBtn.textContent = isReceived ? 'Received!' : 'Mark Flight as Received';
            receiveBtn.style.background = isReceived ? '#0ea5e9' : '#10b981';
            receiveBtn.onclick = null;
        }

        tableBody.innerHTML = `<tr><td colspan="${colSpan}" style="text-align: center; padding: 24px 20px; color: #64748b; font-size: 13px; border:none; background: transparent;">Loading ULDs...</td></tr>`;
        
        const fCarrier = flight.carrier || '';
        const fNumber = flight.number || '';
        const fDate = flight['date-arrived'];
        
        // Forma estricta original
        const refDate = fDate || '';
        const strictFlightRefString = `${fCarrier} ${fNumber} ${refDate}`.trim();
        
        // Forma parcial para búsqueda en BD (ignora conflictos de zona horaria)
        const partialFlightRef = `${fCarrier} ${fNumber}`.trim();

        let { data: ulds, error } = await supabaseClient
            .from('ULD')
            .select('*')
            .eq('refCarrier', fCarrier)
            .eq('refNumber', fNumber)
            .eq('refDate', refDate);

        if (error) {
            console.error('Error fetching ULDs sys:', error);
            tableBody.innerHTML = `<tr><td colspan="${colSpan}" style="text-align: center; padding: 24px 20px; color: #e11d48; font-size: 13px; border:none; background: transparent;">Error loading ULDs</td></tr>`;
            return;
        }

        if (tableBody.id === 'loc-ulds' && ulds) {
            ulds.sort((a, b) => {
                const numA = (a['ULD number'] || '').toLowerCase();
                const numB = (b['ULD number'] || '').toLowerCase();
                if (numA < numB) return -1;
                if (numA > numB) return 1;
                return 0;
            });
        }

        if (tableBody.id === 'coord-ulds' && ulds) {
            ulds = ulds.filter(u => u.isBreak === true || String(u.isBreak).toLowerCase() === 'true' || u.break === true || String(u.break).toLowerCase() === 'true');
            ulds.sort((a, b) => {
                const numA = (a['ULD number'] || '').toLowerCase();
                const numB = (b['ULD number'] || '').toLowerCase();
                if (numA < numB) return -1;
                if (numA > numB) return 1;
                return 0;
            });
        }

        if ((tableBody.id === 'sys-ulds-left' || tableBody.id === 'sys-ulds-right') && ulds) {
            ulds.sort((a, b) => {
                const isBreakA = a.isBreak === true || String(a.isBreak).toLowerCase() === 'true' || a.break === true || String(a.break).toLowerCase() === 'true' ? 1 : 0;
                const isBreakB = b.isBreak === true || String(b.isBreak).toLowerCase() === 'true' || b.break === true || String(b.break).toLowerCase() === 'true' ? 1 : 0;
                if (isBreakA !== isBreakB) {
                    return isBreakB - isBreakA;
                }
                const numA = (a['ULD number'] || '').toLowerCase();
                const numB = (b['ULD number'] || '').toLowerCase();
                if (numA < numB) return -1;
                if (numA > numB) return 1;
                return 0;
            });
        }

        tableBody.innerHTML = '';

        if (!ulds || ulds.length === 0) {
            let emptyMsg = 'No ULDs registered for this flight.';
            if (tableBody.id === 'loc-ulds') emptyMsg = 'No ULDs available for this flight.';
            else if (tableBody.id === 'coord-ulds') emptyMsg = 'No BREAK ULDs available for this flight.';

            tableBody.innerHTML = `<tr><td colspan="${colSpan}" style="text-align: center; padding: 24px 20px; color: #94a3b8; font-size: 13px; border:none; background: transparent;">${emptyMsg}</td></tr>`;
            return;
        }

        let uldReportsMap = {};
        try {
            const { data: flightAwbs, error: awbErr } = await supabaseClient.from('AWB').select('*');
            
            if (flightAwbs && !awbErr) {
                flightAwbs.forEach(awbDoc => {
                    let coordArr = [];
                    if (Array.isArray(awbDoc['data-coordinator'])) coordArr = awbDoc['data-coordinator'];
                    else if (awbDoc['data-coordinator']) { try { coordArr = JSON.parse(awbDoc['data-coordinator']); } catch(e){} }
                    
                    if (Array.isArray(coordArr)) {
                        coordArr.forEach(c => {
                            let expectedDate = fDate ? fDate.split('T')[0] : '';
                            if(!expectedDate && refDate) expectedDate = refDate.split('T')[0];

                            const sameFlight = 
                                String(c.refCarrier || '').trim().toLowerCase() === String(fCarrier).trim().toLowerCase() &&
                                String(c.refNumber || '').trim().toLowerCase() === String(fNumber).trim().toLowerCase() &&
                                expectedDate && String(c.refDate || '').trim().toLowerCase().includes(expectedDate);

                            if (sameFlight && c['Mismatch Report'] && c['Mismatch Report'].trim() !== '') {
                                const associatedULD = c.refULD;
                                if (associatedULD) {
                                    const uldKey = associatedULD.trim().toLowerCase();
                                    if (!uldReportsMap[uldKey]) uldReportsMap[uldKey] = [];
                                    uldReportsMap[uldKey].push(c['Mismatch Report'].trim());
                                }
                            }
                        });
                    }
                });
            }
        } catch(e) { console.warn("Error fetching AWB reports for ULDs:", e); }

        ulds.forEach((uld, index) => {
            const uldNumber = uld['ULD number'] || 'N/A';
            const pieces = uld.pieces || 0;
            const weight = uld.weight || 0;
            const remarks = uld.remarks || '-';
            const isUldBreak = uld.isBreak === true || String(uld.isBreak).toLowerCase() === 'true' || uld.break === true || String(uld.break).toLowerCase() === 'true';
            const isFlightChecked = flight.status === 'Checked' || flight.status === 'Chequeado';

            let rowBg = 'transparent';
            let hoverBg = '#f8fafc';
            if (isSystem && !isUldBreak) {
                rowBg = '#f1f5f9';
                hoverBg = '#e2e8f0';
            }

            const tr = document.createElement('tr');
            tr.setAttribute('data-bg', rowBg);
            tr.setAttribute('data-is-break', isUldBreak ? 'true' : 'false');
            
            // Ambas vistas usarán la expansión interactiva inline
            tr.style.cursor = (tableBody.id === 'loc-ulds' && uld.status !== 'Checked' && uld.status !== 'Ready') ? 'default' : 'pointer';
            tr.style.transition = 'background 0.2s';
            tr.style.background = rowBg;
            
            tr.addEventListener('mouseover', () => { if (!tr.nextElementSibling?.classList.contains('inline-details-row')) tr.style.background = hoverBg; });
            tr.addEventListener('mouseout', () => { if (!tr.nextElementSibling?.classList.contains('inline-details-row')) tr.style.background = rowBg; });

                tr.addEventListener('click', (e) => {
                    if (tableBody.id === 'loc-ulds' && uld.status !== 'Checked' && uld.status !== 'Ready') return; // Bloquear items no cliqueables

                    // Si le dio click directo al checkbox, ignorar expansión
                    if (e.target.classList.contains('sys-uld-checkbox')) return;

                    // Cerrar si ya está abierto
                    const nextRow = tr.nextElementSibling;
                    if (nextRow && nextRow.classList.contains('inline-details-row')) {
                        nextRow.remove();
                        tr.style.background = rowBg;
                        return;
                    }

                    // Forzar cierre de otras filas inline si se desea "acordeón único"
                    const existingInlines = tableBody.querySelectorAll('.inline-details-row');
                    existingInlines.forEach(row => { 
                        if (row.previousElementSibling) row.previousElementSibling.style.background = row.previousElementSibling.getAttribute('data-bg') || 'transparent';
                        row.remove(); 
                    });

                    // Marcar este como activo resaltando el fondo
                    tr.style.background = '#e2e8f0';

                    // Crear fila base para inyección (100% width)
                    const inlineTr = document.createElement('tr');
                    inlineTr.className = 'inline-details-row';
                    inlineTr.innerHTML = `
                        <td colspan="${colSpan}" style="padding: 12px 20px; background: #f8fafc; border-bottom: 2px solid #e2e8f0; animation: fadeIn 0.3s ease;">
                            <div style="background: white; border: 1px solid #cbd5e1; border-radius: 8px; padding: 16px; min-height: 80px; display: flex; center; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);">
                                <span style="margin: auto; color: #64748b; font-size: 13px; font-weight: 500;">Loading Details & AWBs...</span>
                            </div>
                        </td>
                    `;
                    tr.insertAdjacentElement('afterend', inlineTr);

                    // Fetch the AWBs for this ULD async
                    async function fetchInlineData() {
                        window.currentActiveUldRowRefresh = fetchInlineData;
                        const cellBox = inlineTr.querySelector('td > div');
                        try {
                            const { data: awbs, error } = await supabaseClient.from('AWB').select('*');
                            if (error) throw error;
                            
                            let matchedAwbs = [];
                            if (awbs) {
                                awbs.forEach(awbDoc => {
                                    let nestedArr = [];
                                    if (Array.isArray(awbDoc['data-AWB'])) {
                                        nestedArr = awbDoc['data-AWB'];
                                    } else if (awbDoc['data-AWB']) {
                                        try { nestedArr = JSON.parse(awbDoc['data-AWB']); } catch(e){}
                                    }

                                    if (nestedArr.length > 0) {
                                        const nestedData = nestedArr.find(n => 
                                            n.refULD == uldNumber && 
                                            n.refCarrier == fCarrier &&
                                            n.refNumber == fNumber &&
                                            n.refDate == refDate
                                        );
                                        if (nestedData) {
                                            // Check if it has 'data-coordinator' matching this context
                                            let existingCoordObj = null;
                                            if (awbDoc['data-coordinator']) {
                                                let cArr = [];
                                                if (Array.isArray(awbDoc['data-coordinator'])) cArr = awbDoc['data-coordinator'];
                                                else {
                                                    try { cArr = JSON.parse(awbDoc['data-coordinator']); } catch(e){}
                                                }
                                                if (Array.isArray(cArr)) {
                                                    const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                                                    existingCoordObj = cArr.find(c => 
                                                        eqRef(c.refCarrier, fCarrier) &&
                                                        eqRef(c.refNumber, fNumber) &&
                                                        eqRef(c.refDate, refDate) &&
                                                        eqRef(c.refULD, uldNumber)
                                                    );
                                                }
                                            }

                                            let existingLocObj = null;
                                            if (awbDoc['data-location']) {
                                                let lArr = [];
                                                if (Array.isArray(awbDoc['data-location'])) lArr = awbDoc['data-location'];
                                                else {
                                                    try { lArr = JSON.parse(awbDoc['data-location']); } catch(e){}
                                                }
                                                if (Array.isArray(lArr)) {
                                                    const eqRef = (a, b) => String(a || '').trim().toLowerCase() === String(b || '').trim().toLowerCase();
                                                    existingLocObj = lArr.find(c => 
                                                        eqRef(c.refCarrier, fCarrier) &&
                                                        eqRef(c.refNumber, fNumber) &&
                                                        eqRef(c.refDate, refDate) &&
                                                        eqRef(c.refULD, uldNumber)
                                                    );
                                                }
                                            }

                                            matchedAwbs.push({
                                                id: awbDoc.id,
                                                number: awbDoc['AWB number'] || awbDoc.awb_number,
                                                pieces: nestedData.pieces || 0,
                                                total: awbDoc.total || 0,
                                                weight: nestedData.weight || 0,
                                                remarks: nestedData.remarks || '-',
                                                houses: nestedData.house_number || [],
                                                refCarrier: fCarrier,
                                                refNumber: fNumber,
                                                refDate: refDate,
                                                refULD: uldNumber,
                                                coordData: existingCoordObj,
                                                locData: existingLocObj
                                            });
                                        }
                                    }
                                });
                            }

                            const uldPrio = (uld.isPriority || uld.priority) ? '<span style="color:#ef4444; font-weight:700;">Yes</span>' : '<span style="color:#64748b;">No</span>';
                            const uldBrk = (uld.isBreak || uld.break) ? '<span style="color:#4f46e5; font-weight:700;">Break</span>' : '<span style="color:#64748b;">No Break</span>';
                            const remSafe = uld.remarks || 'No notes provided.';

                            let html = `
                                <div style="width:100%; display:flex; flex-direction:column; align-items: stretch;">

                                    <div style="font-size: 11px; color: #4f46e5; font-weight: 700; text-transform: uppercase; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
                                        <span>AWB Shipments Received in this ULD</span>
                                        ${(tableBody.id === 'coord-ulds' && !isFlightChecked) ? `<button onclick="event.stopPropagation(); window.openAddAwbToUldModal('${uldNumber}', '${fCarrier}', '${fNumber}', '${refDate}', ${isUldBreak})" style="background: white; border: 1px solid #e2e8f0; border-radius: 6px; padding: 4px 8px; color: #475569; font-size: 10px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 4px; transition: all 0.2s;" onmouseover="this.style.background='#f8fafc'; this.style.color='#0f172a';" onmouseout="this.style.background='white'; this.style.color='#475569';">
                                            <i class="fas fa-plus"></i> Add Awb
                                        </button>` : ''}
                                    </div>
                            `;

                            if (matchedAwbs.length === 0) {
                                html += '<div style="font-size: 13px; color: #64748b; font-style: italic; background:#f8fafc; padding:12px; border-radius:6px;">No AWBs associated or logged under this PMC format.</div>';
                            } else {
                                html += `
                                    <table style="width: 100%; border-collapse: collapse; text-align: left; background:#fafafa; border-radius: 6px; overflow: hidden; border:1px solid #f1f5f9;">
                                        <thead style="background: #f1f5f9;">
                                            <tr>
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; width: 140px; white-space: nowrap;">AWB Number</th>
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 50px;">Pcs</th>
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 50px;">Total</th>
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 70px;">Weight</th>
                                                ${!isSystem ? `<th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 60px;">Houses</th>
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 90px;">Issues</th>
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; text-align: center; width: 90px;">Status</th>` : ''}
                                                <th style="font-size: 11px; color:#475569; padding: 6px 12px; font-weight: 600; border-bottom: 1px solid #e2e8f0; width: 100%;">Remarks</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                `;
                                
                                matchedAwbs.forEach(awb => {
                                    const hCount = awb.houses.length;
                                    const safeHStr = awb.houses.join(', ').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                    const hBadge = hCount > 0 ? `<span style="background:#e0e7ff; color:#4f46e5; padding:2px 8px; border-radius:10px; font-size:10px; font-weight:600; cursor:pointer;" onclick="event.stopPropagation(); window.showHouseNumbersModal('${safeHStr}')" title="Click to view all">${hCount}</span>` : '<span style="color:#94a3b8; font-size:10px;">0</span>';
                                    
                                    const remEscaped = (awb.remarks || '-').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                    
                                    // Serialize existing data
                                    let encodedData = '';
                                    let encodedLocs = '';
                                    let mismatchBadge = '<span style="color:#cbd5e1; font-size: 10px;">-</span>';
                                    if (awb.coordData) {
                                        encodedData = encodeURIComponent(JSON.stringify(awb.coordData));
                                        if (awb.coordData['Mismatch Report'] && awb.coordData['Mismatch Report'].trim() !== '') {
                                            const safeReport = awb.coordData['Mismatch Report'].replace(/'/g, "\\'").replace(/"/g, '&quot;').replace(/\n/g, '\\n');
                                            mismatchBadge = `<span style="background:#fef08a; color:#854d0e; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:700; cursor: pointer; box-shadow: 0 2px 4px rgba(250,204,21,0.2); display: inline-flex; align-items: center;" title="Click to view explanation" onclick="event.stopPropagation(); window.viewMismatchReport('${safeReport}')"><i class="fas fa-exclamation-triangle" style="margin-right:4px;"></i> REPORT</span>`;
                                        }
                                    }
                                    if (awb.locData) {
                                        encodedLocs = encodeURIComponent(JSON.stringify(awb.locData));
                                    }

                                    const isLocView = tableBody.id === 'loc-ulds';
                                    let checkedBg = '#f1f5f9';
                                    let statusBadge = `<span style="background:#e2e8f0; color:#64748b; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:600;">PENDING</span>`;
                                    
                                    if (isLocView) {
                                        if (awb.locData) {
                                            checkedBg = '#ecfdf5';
                                            let locCheckedBy = (awb.locData.checkedBy || 'Unknown User').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                            let locCheckedAt = awb.locData.checkedAt ? new Date(awb.locData.checkedAt).toLocaleString().replace(/'/g, "\\'").replace(/"/g, '&quot;') : 'Unknown Time';
                                            statusBadge = `<span style="background:#3b82f6; color:white; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:700; box-shadow: 0 2px 4px rgba(59,130,246,0.2); cursor:pointer;" onclick="event.stopPropagation(); window.showCoordinatorCheckInfo('${locCheckedBy}', '${locCheckedAt}')"><i class="fas fa-save" style="margin-right:3px;"></i> SAVED</span>`;
                                        }
                                    } else {
                                        if (awb.coordData) {
                                            checkedBg = '#ecfdf5';
                                            let checkedBy = (awb.coordData.checkedBy || 'Unknown User').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                                            let checkedAt = awb.coordData.checkedAt ? new Date(awb.coordData.checkedAt).toLocaleString().replace(/'/g, "\\'").replace(/"/g, '&quot;') : 'Unknown Time';
                                            statusBadge = `<span style="background:#10b981; color:white; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:700; box-shadow: 0 2px 4px rgba(16,185,129,0.2); cursor: pointer;" onclick="event.stopPropagation(); window.showCoordinatorCheckInfo('${checkedBy}', '${checkedAt}')"><i class="fas fa-check" style="margin-right:3px;"></i> CHECKED</span>`;
                                        }
                                    }

                                    html += `
                                        <tr style="cursor: ${isSystem ? 'default' : 'pointer'}; transition: background 0.2s;" ${!isSystem ? `onmouseover="this.style.background='${checkedBg !== '#f1f5f9' ? '#d1fae5' : '#e2e8f0'}'" onmouseout="this.style.background='transparent'" onclick="window.openInlineAwbModalText('${awb.id}', '${awb.number}', '${awb.pieces}', '${awb.total || 0}', '${awb.weight}', '${safeHStr}', '${remEscaped}', '${awb.refCarrier}', '${awb.refNumber}', '${awb.refDate}', '${awb.refULD}', '${encodedData}', '${encodedLocs}', '${isLocView}', ${isFlightChecked}, ${uld.status === 'Ready'})"` : ''}>
                                            <td style="padding: 10px 12px; font-size: 13px; color: #0f172a; font-weight: 600; border-bottom: 1px solid ${checkedBg}; white-space: nowrap;">
                                                ${awb.number}
                                            </td>
                                            <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${awb.pieces}</td>
                                            <td style="padding: 10px 12px; font-size: 12px; color: #0f172a; border-bottom: 1px solid ${checkedBg}; text-align: center; font-weight: 700;">${awb.total || 0}</td>
                                            <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${awb.weight}</td>
                                            ${!isSystem ? `<td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${hBadge}</td>
                                            <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${mismatchBadge}</td>
                                            <td style="padding: 10px 12px; font-size: 12px; color: #475569; border-bottom: 1px solid ${checkedBg}; text-align: center;">${statusBadge}</td>` : ''}
                                            <td style="padding: 10px 12px; font-size: 12px; color: #64748b; border-bottom: 1px solid ${checkedBg}; max-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="${awb.remarks}">${awb.remarks}</td>
                                        </tr>
                                    `;
                                });
                                html += '</tbody></table>';
                            }
                            
                            html += '</div>';
                            cellBox.style.display = 'block';
                            cellBox.innerHTML = html;
                            
                            // Update button state logic for Coordinator / Locator
                            const isLocModeExt = tableBody.id === 'loc-ulds';
                            const isUldFullyChecked = matchedAwbs.length > 0 && matchedAwbs.every(a => isLocModeExt ? a.locData : a.coordData);
                            const checkBtn = tr.querySelector('.coord-uld-check-btn');
                            
                            if (checkBtn) {
                                if (isLocModeExt) {
                                    const isAlreadyReady = uld.status === 'Ready' || checkBtn.getAttribute('data-status') === 'Ready';
                                    
                                    if (isAlreadyReady && isUldFullyChecked) {
                                        checkBtn.innerHTML = '<i class="fas fa-check" style="margin-right:4px;"></i> SAVED';
                                        checkBtn.style.background = '#10b981';
                                        checkBtn.style.color = 'white';
                                        checkBtn.disabled = true;
                                        checkBtn.style.cursor = 'default';
                                    } else if (isUldFullyChecked) {
                                        checkBtn.innerHTML = 'MARK SAVED';
                                        checkBtn.style.background = '#8b5cf6';
                                        checkBtn.style.color = 'white';
                                        checkBtn.disabled = false;
                                        checkBtn.style.cursor = 'pointer';
                                    } else if (uld.status === 'Checked') {
                                        checkBtn.innerHTML = 'READY TO SAVE';
                                        checkBtn.style.background = '#3b82f6';
                                        checkBtn.style.color = 'white';
                                        checkBtn.disabled = true;
                                        checkBtn.style.cursor = 'default';
                                    } else {
                                        checkBtn.innerHTML = 'PENDING TO CHECK';
                                        checkBtn.style.background = '#e2e8f0';
                                        checkBtn.style.color = '#94a3b8';
                                        checkBtn.disabled = true;
                                        checkBtn.style.cursor = 'not-allowed';
                                        
                                        if (uld.status === 'Ready') {
                                             supabaseClient.from('ULD').update({status: 'Checked'}).eq('id', uld.id).then();
                                             uld.status = 'Checked';
                                             checkBtn.removeAttribute('data-status');
                                        }
                                    }
                                } else {
                                    const isAlreadyChecked = uld.status === 'Checked' || checkBtn.getAttribute('data-status') === 'Checked';
                                    
                                     if (isAlreadyChecked && isUldFullyChecked) {
                                        checkBtn.innerHTML = '<i class="fas fa-check" style="margin-right:4px;"></i> CHECKED';
                                        checkBtn.style.background = '#10b981';
                                        checkBtn.style.color = 'white';
                                        checkBtn.disabled = true;
                                        checkBtn.style.cursor = 'default';
                                    } else if (isUldFullyChecked) {
                                        checkBtn.innerHTML = 'CHECK ULD';
                                        checkBtn.style.background = '#4f46e5';
                                        checkBtn.style.color = 'white';
                                        checkBtn.disabled = false;
                                        checkBtn.style.cursor = 'pointer';
                                    } else {
                                        checkBtn.innerHTML = 'PENDING TO CHECK';
                                        checkBtn.style.background = '#e2e8f0';
                                        checkBtn.style.color = '#94a3b8';
                                        checkBtn.disabled = true;
                                        checkBtn.style.cursor = 'not-allowed';
                                        
                                        if (uld.status === 'Checked' || uld.status === 'Ready') {
                                             supabaseClient.from('ULD').update({status: 'Pending'}).eq('id', uld.id).then();
                                             uld.status = 'Pending';
                                             checkBtn.removeAttribute('data-status');
                                        }
                                    }
                                }
                            }

                            // Re-calculate the Mismatch Report count for this precise ULD
                            if (tableBody.id === 'coord-ulds') {
                                const reportCell = tr.querySelector('.uld-report-cell');
                                if (reportCell) {
                                    let uldReportsForTr = [];
                                    matchedAwbs.forEach(awb => {
                                        if (awb.coordData && awb.coordData['Mismatch Report'] && awb.coordData['Mismatch Report'].trim() !== '') {
                                            uldReportsForTr.push(awb.coordData['Mismatch Report'].trim());
                                        }
                                    });
                                    let updatedMismatchHtml = '<span style="color:#94a3b8; font-size:12px; font-weight:600;">0</span>';
                                    if (uldReportsForTr.length > 0) {
                                        const formattedReports = uldReportsForTr.map((req, i) => `<b>Report ${i + 1}:</b><br>${req}`).join('<br><br>');
                                        const safeReport = formattedReports.replace(/'/g, "\\'").replace(/"/g, '&quot;').replace(/\n/g, '<br>');
                                        updatedMismatchHtml = `<div title="Click to view Report" 
                                            style="display:inline-flex; align-items:center; justify-content:center; background:#fee2e2; color:#b91c1c; width:22px; height:22px; min-width:22px; border-radius:50%; font-size:11px; font-weight:bold; cursor:pointer;" 
                                            onclick="event.stopPropagation(); window.viewMismatchReport('${safeReport}')">
                                            ${uldReportsForTr.length}
                                        </div>`;
                                    }
                                    reportCell.innerHTML = updatedMismatchHtml;
                                }
                            }

                        } catch(err) {
                            cellBox.innerHTML = '<span style="color:#ef4444; font-size: 13px; font-weight:500;">Failed to load data for this PMC.</span>';
                        }
                    }
                    
                    fetchInlineData();
                });

                let initBtnHtml = 'PENDING';
                let initBtnBg = '#e2e8f0';
                let initBtnColor = '#94a3b8';
                let initBtnCursor = 'not-allowed';
                
                if (tableBody.id === 'loc-ulds') {
                    if (uld.status === 'Ready') {
                        initBtnHtml = '<i class="fas fa-check" style="margin-right:4px;"></i> SAVED';
                        initBtnBg = '#10b981';
                        initBtnColor = 'white';
                        initBtnCursor = 'default';
                    } else if (uld.status === 'Checked') {
                        initBtnHtml = 'READY TO SAVE';
                        initBtnBg = '#3b82f6';
                        initBtnColor = 'white';
                        initBtnCursor = 'pointer';
                    } else {
                        initBtnHtml = 'PENDING TO CHECK';
                        initBtnBg = '#e2e8f0';
                        initBtnColor = '#94a3b8';
                        initBtnCursor = 'not-allowed';
                    }
                } else if (tableBody.id === 'coord-ulds') {
                    if (uld.status === 'Checked' || uld.status === 'Ready') {
                        initBtnHtml = '<i class="fas fa-check" style="margin-right:4px;"></i> CHECKED';
                        initBtnBg = '#10b981';
                        initBtnColor = 'white';
                        initBtnCursor = 'default';
                    }
                }

                let mismatchHtml = '<span style="color:#94a3b8; font-size:12px; font-weight:600;">0</span>';
                const uldKeyForMatch = uldNumber.trim().toLowerCase();
                const uReports = uldReportsMap[uldKeyForMatch];
                if (uReports && uReports.length > 0) {
                    const formattedReports = uReports.map((req, i) => `<b>Report ${i + 1}:</b><br>${req}`).join('<br><br>');
                    const safeReport = formattedReports.replace(/'/g, "\\'").replace(/"/g, '&quot;').replace(/\n/g, '<br>');
                    
                    mismatchHtml = `<div title="Click to view Report" 
                        style="display:inline-flex; align-items:center; justify-content:center; background:#fee2e2; color:#b91c1c; width:22px; height:22px; min-width:22px; border-radius:50%; font-size:11px; font-weight:bold; cursor:pointer;" 
                        onclick="event.stopPropagation(); window.viewMismatchReport('${safeReport}')">
                        ${uReports.length}
                    </div>`;
                }

                tr.innerHTML = `
                    <td style="text-align: center; color: #94a3b8; font-weight: 500;">
                        ${index + 1}
                    </td>
                    <td>
                        <div style="font-weight: 600; color: #334155; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${uldNumber}</div>
                    </td>
                    <td style="text-align: center; white-space: nowrap;">${pieces}</td>
                    <td style="text-align: center; white-space: nowrap;">${weight} kg</td>
                    ${isSystem ? `<td style="text-align: center; white-space: nowrap;">
                        ${isUldBreak ? '<span style="background: #dcfce7; color: #166534; padding: 4px 10px; border-radius: 12px; font-weight: 700; font-size: 10px; border: 1px solid #bbf7d0; display: inline-block; width: 75px; text-align: center; box-sizing: border-box; white-space: nowrap;">BREAK</span>' : '<span style="background: #fee2e2; color: #991b1b; padding: 4px 10px; border-radius: 12px; font-weight: 700; font-size: 10px; border: 1px solid #fecaca; display: inline-block; width: 75px; text-align: center; box-sizing: border-box; white-space: nowrap;">NO-BREAK</span>'}
                    </td>` : ''}
                    ${tableBody.id === 'coord-ulds' ? `<td style="text-align: center;" class="uld-report-cell">${mismatchHtml}</td>` : ''}
                    <td style="color: #64748b; font-size: 13px; max-width: 0; padding-left: ${isSystem ? '24px' : '0'};">
                        <div style="width: 100%; overflow-x: auto; white-space: nowrap; padding-bottom: 2px; scrollbar-width: thin;">
                            ${remarks}
                        </div>
                    </td>
                    ${isCoordinator ? `<td style="text-align: right;">
                        <div style="display: flex; justify-content: flex-end; align-items: center; height: 100%;">
                            <button class="coord-uld-check-btn" data-status="${uld.status}" onclick="event.stopPropagation(); window.markUldAsChecked('${uld.id}', '${uldNumber}', this, ${tableBody.id === 'loc-ulds'}, '${flight.id || ''}')" style="padding: 6px 12px; font-size: 10px; font-weight: 700; border-radius: 6px; border: none; background: ${initBtnBg}; color: ${initBtnColor}; cursor: ${initBtnCursor}; white-space: nowrap; transition: all 0.2s;" disabled>
                                ${initBtnHtml}
                            </button>
                        </div>
                    </td>` : `<td style="text-align: right;">
                        <div style="display: flex; justify-content: flex-end; align-items: center; height: 100%;">
                            <input type="checkbox" class="sys-uld-checkbox" data-uld-id="${uld.id}" ${isReceived ? 'checked disabled' : ''} style="width: 18px; height: 18px; cursor: ${isReceived ? 'default' : 'pointer'}; accent-color: #4f46e5; border-radius: 4px; border: 1px solid #cbd5e1; outline: none; box-shadow: none;">
                        </div>
                    </td>`}
                `;
            
            tableBody.appendChild(tr);
        });

        // Event listener for activating the receiveBtn
        const localUldTimes = {};
        const checkboxes = tableBody.querySelectorAll('.sys-uld-checkbox');
        const checkAll = (e) => {
            if (checkboxes.length === 0) return;
            const checkedCount = Array.from(checkboxes).filter(cb => cb.checked).length;
            const allChecked = checkedCount === checkboxes.length;
            
            if (e && e.target) {
                const uldId = e.target.getAttribute('data-uld-id');
                if (uldId && e.target.checked) {
                    const formatter = new Intl.DateTimeFormat('en-US', {
                        timeZone: 'America/Chicago',
                        year: 'numeric', month: '2-digit', day: '2-digit',
                        hour: '2-digit', minute: '2-digit', second: '2-digit',
                        hour12: false
                    });
                    const p = {};
                    formatter.formatToParts(new Date()).forEach(part => p[part.type] = part.value);
                    const h = p.hour === '24' ? '00' : p.hour;
                    const chicagoTime = `${p.year}-${p.month}-${p.day}T${h}:${p.minute}:${p.second}`;
                    localUldTimes[uldId] = chicagoTime;
                    
                    // Updated: Send actual update payload to ULD database
                    supabaseClient.from('ULD').update({
                        status: 'Received',
                        'time-received': chicagoTime
                    }).eq('id', uldId).then(({error}) => {
                        if (error) console.error("Error updating ULD status to Received:", error);
                    });
                }
            }

            // Logica para first-truck (actualizar si se acaba de hacer el primer check, incluso si hubo deselecciones previas)
            if (e && e.target && e.target.checked && checkedCount === 1) {
                const formatter = new Intl.DateTimeFormat('en-US', {
                    timeZone: 'America/Chicago',
                    year: 'numeric', month: '2-digit', day: '2-digit',
                    hour: '2-digit', minute: '2-digit', second: '2-digit',
                    hour12: false
                });
                const p = {};
                formatter.formatToParts(new Date()).forEach(part => p[part.type] = part.value);
                const h = p.hour === '24' ? '00' : p.hour;
                const nowChicagoIso = `${p.year}-${p.month}-${p.day}T${h}:${p.minute}:${p.second}`;
                
                flight['first-truck'] = nowChicagoIso; // Marcar en memoria local
                
                supabaseClient.from('Flight').update({'first-truck': nowChicagoIso}).eq('id', flight.id).then(({error}) => {
                    if (error) {
                        supabaseClient.from('flights').update({'first-truck': nowChicagoIso}).eq('id', flight.id).catch(err=>console.error(err));
                    }
                });
            }

            if (receiveBtn) {
                if (allChecked) {
                    receiveBtn.disabled = false;
                    receiveBtn.style.opacity = '1';
                    receiveBtn.style.cursor = 'pointer';
                } else {
                    receiveBtn.disabled = true;
                    receiveBtn.style.opacity = '0.5';
                    receiveBtn.style.cursor = 'not-allowed';
                }
            }
            if (window.updateTableCounters) window.updateTableCounters(tableBody.id);
        };

        checkboxes.forEach(cb => cb.addEventListener('change', checkAll));
        if (window.updateTableCounters) window.updateTableCounters(tableBody.id);

        // Submit listener for Receive btn
        if (receiveBtn) {
            receiveBtn.onclick = async () => {
                receiveBtn.disabled = true;
                const originalText = receiveBtn.textContent;
                receiveBtn.textContent = 'Updating...';
                const formatter = new Intl.DateTimeFormat('en-US', {
                    timeZone: 'America/Chicago',
                    year: 'numeric', month: '2-digit', day: '2-digit',
                    hour: '2-digit', minute: '2-digit', second: '2-digit',
                    hour12: false
                });
                const p = {};
                formatter.formatToParts(new Date()).forEach(part => p[part.type] = part.value);
                const h = p.hour === '24' ? '00' : p.hour;
                const nowChicagoIso = `${p.year}-${p.month}-${p.day}T${h}:${p.minute}:${p.second}`;

                let updateData = { status: 'Received', 'last-truck': nowChicagoIso };
                
                let { error: errUpdate } = await supabaseClient
                    .from('Flight')
                    .update(updateData)
                    .eq('id', flight.id);
                    
                if (errUpdate) {
                    const fallback = await supabaseClient
                        .from('flights')
                        .update(updateData)
                        .eq('id', flight.id);
                    errUpdate = fallback.error;
                }
                
                if (errUpdate) {
                    console.error('Error updating flight status:', errUpdate);
                    alert('Error: Could not mark as received.');
                    receiveBtn.disabled = false;
                    receiveBtn.textContent = originalText;
                } else {
                    receiveBtn.textContent = 'Received!';
                    receiveBtn.style.background = '#0ea5e9';
                    receiveBtn.style.cursor = 'default';
                    
                    Array.from(checkboxes).forEach(cb => {
                        if (cb.checked) {
                            const uId = cb.getAttribute('data-uld-id');
                            let timeStr = (uId && localUldTimes[uId]) ? localUldTimes[uId] : nowChicagoIso;
                            if (uId) {
                                supabaseClient.from('ULD').update({ 'time-received': timeStr }).eq('id', uId).then();
                            }
                        }
                    });

                    checkboxes.forEach(cb => {
                        cb.checked = true;
                        cb.disabled = true;
                        cb.style.cursor = 'default';
                    });
                    
                    flight.status = 'Received'; // Refresh local ui state
                    if (window.updateTableCounters) window.updateTableCounters(tableBody.id);
                    
                    // Mark choice chips explicitly as completed
                    const chips = document.querySelectorAll(`.choice-chip[data-flight-id="${flight.id}"]`);
                    chips.forEach(chip => {
                        if (chip.closest('#loc-flights')) return;
                        chip.style.backgroundColor = '#dcfce7'; // warm green background
                        chip.style.color = '#166534'; // warm green text
                        chip.style.borderColor = '#bbf7d0'; // border
                    });
                }
            };
        }

        // Add logic for coord-check-flight-btn
        if (tableBody.id === 'coord-ulds') {
            const coordCheckBtn = document.getElementById('coord-check-flight-btn');
            if (coordCheckBtn) {
                const isFlightChecked = flight.status === 'Checked' || flight.status === 'Chequeado';
                
                if (isFlightChecked) {
                    coordCheckBtn.disabled = true;
                    coordCheckBtn.style.opacity = '1';
                    coordCheckBtn.style.cursor = 'default';
                    coordCheckBtn.textContent = 'CHECKED';
                    coordCheckBtn.style.background = '#8b5cf6';
                    coordCheckBtn.onclick = null;
                } else {
                    coordCheckBtn.textContent = 'Mark Flight as Checked';
                    coordCheckBtn.style.background = '#10b981';
                    
                    setTimeout(window.checkFlightReadyStatus, 150);
                    
                    coordCheckBtn.onclick = async () => {
                        coordCheckBtn.disabled = true;
                        const originalText = coordCheckBtn.textContent;
                        coordCheckBtn.textContent = 'Updating...';
                        
                        // Create a precise string for Chicago Time (YYYY-MM-DDTHH:mm:ss)
                        const formatter = new Intl.DateTimeFormat('en-US', {
                            timeZone: 'America/Chicago',
                            year: 'numeric', month: '2-digit', day: '2-digit',
                            hour: '2-digit', minute: '2-digit', second: '2-digit',
                            hour12: false
                        });
                        const p = {};
                        formatter.formatToParts(new Date()).forEach(part => p[part.type] = part.value);
                        const h = p.hour === '24' ? '00' : p.hour;
                        const nowChicagoIso = `${p.year}-${p.month}-${p.day}T${h}:${p.minute}:${p.second}`;

                        let updateData = { status: 'Checked', 'end-break': nowChicagoIso };
                        
                        let { error: errUpdate } = await supabaseClient
                            .from('Flight')
                            .update(updateData)
                            .eq('id', flight.id);
                            
                        if (errUpdate) {
                            const fallback = await supabaseClient
                                .from('flights')
                                .update(updateData)
                                .eq('id', flight.id);
                            errUpdate = fallback.error;
                        }
                        
                        if (errUpdate) {
                            console.error('Error updating flight status:', errUpdate);
                            alert('Error: Could not mark as checked.');
                            coordCheckBtn.disabled = false;
                            coordCheckBtn.textContent = originalText;
                        } else {
                            coordCheckBtn.textContent = 'CHECKED';
                            coordCheckBtn.style.background = '#8b5cf6';
                            coordCheckBtn.style.cursor = 'default';
                            flight.status = 'Checked'; 
                            
                            // Mark choice chip explicitly as completed
                            const chips = document.querySelectorAll(`.choice-chip[data-flight-id="${flight.id}"]`);
                            chips.forEach(chip => {
                                if (chip.closest('#loc-flights')) return;
                                chip.style.backgroundColor = '#dcfce7'; // warm green background
                                chip.style.color = '#166534'; // warm green text
                                chip.style.borderColor = '#bbf7d0'; // border
                            });

                            if (window.fetchFlights) window.fetchFlights();
                        }
                    };
                }
            }
        }
        
        if (tableBody.id === 'coord-ulds') {
            window.refreshFlightDiscrepancies(flight);
        }

        if (tableBody.id === 'loc-ulds') {
            const locReadyBtn = document.getElementById('loc-ready-flight-btn');
            if (locReadyBtn) {
                const isFlightReady = flight.status === 'Ready' || flight.status === 'Listo';

                if (isFlightReady) {
                    locReadyBtn.disabled = true;
                    locReadyBtn.style.opacity = '1';
                    locReadyBtn.style.cursor = 'default';
                    locReadyBtn.textContent = 'READY';
                    locReadyBtn.style.background = '#8b5cf6';
                    locReadyBtn.onclick = null;
                } else {
                    locReadyBtn.textContent = 'Mark Flight as Ready';
                    locReadyBtn.style.background = '#10b981';

                    setTimeout(window.checkLocFlightReadyStatus, 150);

                    locReadyBtn.onclick = async () => {
                        locReadyBtn.disabled = true;
                        const originalText = locReadyBtn.textContent;
                        locReadyBtn.textContent = 'Updating...';

                        let updateData = { status: 'Ready' };

                        let { error: errUpdate } = await supabaseClient
                            .from('Flight')
                            .update(updateData)
                            .eq('id', flight.id);

                        if (errUpdate) {
                            const fallback = await supabaseClient
                                .from('flights')
                                .update(updateData)
                                .eq('id', flight.id);
                            errUpdate = fallback.error;
                        }

                        if (errUpdate) {
                            console.error('Error updating flight status:', errUpdate);
                            alert('Error: Could not mark as ready.');
                            locReadyBtn.disabled = false;
                            locReadyBtn.textContent = originalText;
                        } else {
                            locReadyBtn.textContent = 'READY';
                            locReadyBtn.style.background = '#8b5cf6';
                            locReadyBtn.style.cursor = 'default';
                            flight.status = 'Ready';

                            const chips = document.querySelectorAll(`.choice-chip[data-flight-id="${flight.id}"]`);
                            chips.forEach(chip => {
                                chip.style.backgroundColor = '#dcfce7';
                                chip.style.color = '#166534';
                                chip.style.borderColor = '#bbf7d0';
                            });

                            if (window.fetchFlights) window.fetchFlights();
                        }
                    };
                }
            }
        }
    }

    // Suscribir inputs de fecha
    if (sysDateLeft) {
        sysDateLeft.addEventListener('change', (e) => {
            loadFlightsForSystem(e.target.value, sysFlightsLeft, sysUldsLeft, sysReceiveBtnLeft);
        });
    }
    
    if (sysDateRight) {
        sysDateRight.addEventListener('change', (e) => {
            loadFlightsForSystem(e.target.value, sysFlightsRight, sysUldsRight, sysReceiveBtnRight);
        });
    }

    // ------- COORDINATOR WORKFLOW LOGIC -------
    const coordDate = document.getElementById('coord-date');
    const coordFlights = document.getElementById('coord-flights');
    const coordUlds = document.getElementById('coord-ulds');

    if (coordDate) {
        coordDate.addEventListener('change', (e) => {
            // Reusing the system functionality without a receiveBtn
            loadFlightsForSystem(e.target.value, coordFlights, coordUlds);
        });
    }

    // ------- LOCATION WORKFLOW LOGIC -------
    const locDate = document.getElementById('loc-date');
    const locFlights = document.getElementById('loc-flights');
    const locUlds = document.getElementById('loc-ulds');

    if (locDate) {
        locDate.addEventListener('change', (e) => {
            // Reusing the system functionality without a receiveBtn (just like Coordinator)
            loadFlightsForSystem(e.target.value, locFlights, locUlds);
        });
    }

    // ------- MANEJAR REGISTRO (register.html) -------
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            const name = document.getElementById('name').value; 
            const confirmPassword = document.getElementById('confirm-password').value;
            const btn = registerForm.querySelector('button[type="submit"]');

            if (password !== confirmPassword) {
                alert('Las contraseñas no coinciden.');
                return;
            }

            btn.disabled = true;
            btn.textContent = 'Registrando...';

            const { data, error } = await supabaseClient.auth.signUp({
                email: email,
                password: password,
                options: { data: { name: name } }
            });

            if (error) {
                alert('Error al registrar: ' + error.message);
                btn.disabled = false;
                btn.textContent = 'Registrarse';
            } else {
                alert('¡Registro exitoso! Iniciando sesión automáticamente...');
                window.location.href = 'index.html';
            }
        });
    }
    window.confirmCoordinatorSave = function() {
        const reportEl = document.getElementById('awb-mismatch-overlay-report');
        const errorMsg = document.getElementById('mismatch-error-msg');
        
        // Ensure no error messages block since input is automatic now
        if (errorMsg) errorMsg.style.display = 'none';

        document.getElementById('mismatch-overlay-modal').style.display = 'none';
        
        if (typeof window.mismatchConfirmCallback === 'function') {
            const cb = window.mismatchConfirmCallback;
            window.mismatchConfirmCallback = null;
            cb();
        } else {
            const svBtn = document.getElementById('inline-awb-save-btn');
            window.saveCoordinatorData(svBtn, true);
        }
    };

    window.viewMismatchReport = function(reportText) {
        const modal = document.getElementById('mismatch-view-modal');
        const textEl = document.getElementById('mismatch-view-report-text');
        if (modal && textEl) {
            textEl.innerHTML = reportText; // Now uses HTML to respect line breaks and bold tags
            modal.style.display = 'flex';
        }
    };

    // ----- DELIVERIES SYSTEM -----
    window.loadDeliveries = async function() {
        const tableBody = document.getElementById('delivers-table-body');
        tableBody.innerHTML = '<tr><td colspan="10" class="loading-td" style="color:#64748b; font-style:italic;">Loading deliveries...</td></tr>';
        
        try {
            let data, error;
            const res = await supabaseClient.from('Delivers')
                .select('*')
                .order('sort_order', { ascending: true, nullsFirst: false })
                .order('isPriority', { ascending: false, nullsFirst: false })
                .order('created_at', { ascending: false });

            if (res.error && res.error.code === '42703') {
                const fallback = await supabaseClient.from('Delivers')
                    .select('*')
                    .order('isPriority', { ascending: false, nullsFirst: false })
                    .order('created_at', { ascending: false });
                data = fallback.data;
                error = fallback.error;
            } else {
                data = res.data;
                error = res.error;
            }

            if (error) throw error;
            
            tableBody.innerHTML = '';
            if (!data || data.length === 0) {
                tableBody.innerHTML = '<tr><td colspan="11" style="text-align:center; padding: 24px 20px; color:#94a3b8; font-style:italic; border:none; font-size: 13px;">No deliveries registered yet.</td></tr>';
                return;
            }
            
            window.activeDeliveries = data || [];
            
            window.activeDeliveries.forEach((del, index) => {
                const tr = document.createElement('tr');
                let waitTimeText = '-';
                if (del.created_at) {
                    const createdDate = new Date(del.created_at);
                    const now = new Date();
                    const diffMs = now - createdDate;
                    const diffMins = Math.floor(diffMs / 60000);
                    
                    if (diffMins < 60) {
                        waitTimeText = `${diffMins} min`;
                    } else if (diffMins < 1440) {
                        const hrs = Math.floor(diffMins / 60);
                        const remMins = diffMins % 60;
                        waitTimeText = `${hrs}h ${remMins}m`;
                    } else {
                        const days = Math.floor(diffMins / 1440);
                        waitTimeText = `${days} d`;
                    }
                }
                const statusBadge = `<span style="display:inline-block; width:80px; text-align:center; background:#dbeafe; color:#1e40af; padding:4px 10px; border-radius:12px; font-size:10px; font-weight:700;">IN TRANSIT</span>`;
                
                const priorityToggleText = del.isPriority ? '<span style="color:#16a34a; font-weight:700;">Yes</span>' : '<span style="color:#94a3b8;">No</span>';
                
                tr.innerHTML = `
                    <td class="drag-handle" style="color: #94a3b8; cursor: grab; text-align: center;" title="Drag to reorder">
                        <i class="fas fa-grip-vertical"></i>
                    </td>
                    <td class="row-index" style="font-weight: 600; color: #64748b; text-align: center;">${index + 1}</td>
                    <td style="color: #475569;">${del['truck-company'] || '-'}</td>
                    <td style="font-weight: 600; color: #334155;">${del.driver || '-'}</td>
                    <td style="color: #475569;">${del.door || '-'}</td>
                    <td style="color: #475569;">${del['id-pickup'] || '-'}</td>
                    <td style="color: #475569; font-weight: 500; text-align: center;">${waitTimeText}</td>
                    <td style="font-size: 13px; text-align: center;">${priorityToggleText}</td>
                    <td style="color: #4f46e5; font-weight: 600; font-size: 13px;">${del.type || 'Normal'}</td>
                    <td style="color: #64748b; font-size: 12px; font-style: italic; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 140px; padding-left: 8px;" title="${del.remarks || ''}">${del.remarks || '-'}</td>
                    <td style="text-align: center;">${statusBadge}</td>
                `;
                
                // Add click listener to open Drawer
                tr.style.cursor = 'pointer';
                tr.addEventListener('click', () => {
                   document.getElementById('drawer-delivery-company').textContent = del['truck-company'] || '-';
                   document.getElementById('drawer-delivery-driver').textContent = del.driver || '-';
                   document.getElementById('drawer-delivery-door').textContent = del.door || '-';
                   document.getElementById('drawer-delivery-id-pickup').textContent = del['id-pickup'] || '-';
                   
                   const awbListEl = document.getElementById('drawer-delivery-awbs-list');
                   awbListEl.innerHTML = '';
                   
                   const listPickup = del['list-pickup'] || [];
                   if (listPickup.length === 0) {
                        awbListEl.innerHTML = '<div style="font-size: 13px; color: #64748b; font-style: italic;">No AWBs recorded.</div>';
                   } else {
                       listPickup.forEach((item, index) => {
                           let titleStr = '';
                           let metaStr = '';
                           
                           let parsedItem = item;
                           if (typeof item === 'string') {
                               try {
                                   parsedItem = JSON.parse(item);
                               } catch(e) { /* ignore */ }
                           }

                           if (typeof parsedItem === 'string') {
                               titleStr = parsedItem;
                           } else {
                               // It's our new rich object structure or from another source
                               titleStr = parsedItem.number || parsedItem['AWB number'] || 'Unknown AWB';
                               let pDets = [];
                               if (parsedItem.totalReceived && parsedItem.totalExpected) {
                                  pDets.push(`<b>${parsedItem.totalReceived}/${parsedItem.totalExpected}</b> Pcs`);
                               }
                               if (parsedItem.pallet && parsedItem.pallet !== '-') {
                                   pDets.push(`Pallet: ${parsedItem.pallet}`);
                               }
                               if (parsedItem.flight && parsedItem.flight !== '-') {
                                   pDets.push(`Flight: ${parsedItem.flight}`);
                               }
                               if(pDets.length > 0) metaStr = `<div style="font-size: 11px; color:#64748b; margin-top: 4px;">${pDets.join(' • ')}</div>`;
                           }
                           
                           awbListEl.innerHTML += `
                               <div style="display: flex; position: relative; width: 100%;">
                                   ${index < listPickup.length - 1 ? '<div style="position: absolute; left: 13px; top: 32px; bottom: -12px; width: 2px; background: #e2e8f0; z-index: 1;"></div>' : ''}
                                   <div style="position: relative; z-index: 2; width: 28px; height: 28px; border-radius: 50%; background: #ffffff; border: 2px solid #cbd5e1; color: #475569; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; flex-shrink: 0; margin-top: 4px;">${index + 1}</div>
                                   <div style="flex: 1; margin-left: 16px; display: flex; justify-content: space-between; align-items: flex-start; padding: 14px; border: 1px solid #e2e8f0; border-radius: 8px; background: #f8fafc; box-shadow: 0 1px 2px rgba(0,0,0,0.02);">
                                       <div style="display:flex; flex-direction: column;">
                                           <div style="font-weight: 600; color: #0f172a; font-size: 13px;"><i class="fas fa-file-alt" style="color:#64748b; margin-right: 6px;"></i> ${titleStr}</div>
                                           ${metaStr}
                                       </div>
                                       <div style="font-size: 10px; font-weight: 700; color: #166534; background: #dcfce7; border: 1px solid #bbf7d0; padding: 3px 8px; border-radius: 12px;">DELIVERED</div>
                                   </div>
                               </div>
                           `;
                       });
                   }
                   
                   const overlay = document.getElementById('delivery-drawer-overlay');
                   if (overlay) overlay.classList.add('open');
                   setTimeout(() => {
                       document.getElementById('delivery-drawer').style.right = '0';
                   }, 10);
                });
                
                tableBody.appendChild(tr);
            });
            
            // Drawer Close button listener
            const closeDeliveryDrawerBtn = document.getElementById('close-delivery-drawer-btn');
            if (closeDeliveryDrawerBtn && !closeDeliveryDrawerBtn.dataset.listenerAttached) {
                closeDeliveryDrawerBtn.dataset.listenerAttached = 'true';
                closeDeliveryDrawerBtn.addEventListener('click', () => {
                    document.getElementById('f-break').value = '';
                    document.getElementById('f-nobreak').value = '';
                    document.getElementById('delivery-drawer').style.right = '-100%';
                    const overlay = document.getElementById('delivery-drawer-overlay');
                    if(overlay) overlay.classList.remove('open');
                });
            }
            // Close on overlay click
            const deliveryDrawerOverlay = document.getElementById('delivery-drawer-overlay');
            if (deliveryDrawerOverlay && !deliveryDrawerOverlay.dataset.listenerAttached) {
                deliveryDrawerOverlay.dataset.listenerAttached = 'true';
                deliveryDrawerOverlay.addEventListener('click', () => {
                    document.getElementById('delivery-drawer').style.right = '-100%';
                    deliveryDrawerOverlay.classList.remove('open');
                });
            }
            
            // Initialize Sortable setup allowing drag-and-drop to visually reorder items if desired
            if (window.Sortable) {
                new Sortable(tableBody, {
                    animation: 150,
                    handle: '.drag-handle',
                    ghostClass: 'sortable-ghost',
                    onEnd: function (evt) {
                        const item = window.activeDeliveries.splice(evt.oldIndex, 1)[0];
                        window.activeDeliveries.splice(evt.newIndex, 0, item);
                        
                        // Update the index display visually
                        const rows = tableBody.querySelectorAll('tr');
                        rows.forEach((r, idx) => {
                            const idxTd = r.querySelector('.row-index');
                            if(idxTd) idxTd.textContent = idx + 1;
                        });

                        if(window.renderDriverQueue) window.renderDriverQueue();
                        
                        // Silently Sync new order index to Supabase if sort_order col exists
                        window.activeDeliveries.forEach((d, i) => {
                            supabaseClient.from('Delivers').update({ sort_order: i }).eq('id', d.id).then(({error}) => {
                                if (error && error.code !== '42703') console.warn('Order sync error:', error);
                            });
                        });
                    }
                });
            }
            
            if (window.renderDriverQueue) window.renderDriverQueue();

        } catch (err) {
            console.error('Error loading deliveries:', err);
            // Si la tabla no existe, mostramos esto por ahora para no crashear
            tableBody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding: 24px 20px; color:#e11d48; font-size: 13px; border:none;">List is empty or "delivers" table does not exist in Supabase yet.</td></tr>';
        }
    };

    window.renderDriverQueue = function() {
        const container = document.getElementById('driver-current-info');
        if (!container) return;
        
        if (!window.activeDeliveries || window.activeDeliveries.length === 0) {
            container.innerHTML = `
                <div style="text-align: center; color: #64748b; padding: 60px; width: 100%; max-width: 500px; background: white; border-radius: 12px; border: 1px dashed #cbd5e1; margin: 0 auto;">
                    <i class="fas fa-mug-hot fa-3x" style="color: #cbd5e1; margin-bottom: 16px;"></i>
                    <h2 style="margin:0; font-size: 18px; color:#334155;">Queue Empty</h2>
                    <p style="margin-top: 8px; font-size: 14px;">No drivers are currently waiting for delivery.</p>
                </div>
            `;
            return;
        }

        const currentDriver = window.activeDeliveries[0];
        
        let awbsHtml = '<div style="font-size: 13px; color: #64748b; font-style: italic;">No AWBs assigned.</div>';
        const listPickup = currentDriver['list-pickup'] || [];
        if (listPickup.length > 0) {
            awbsHtml = listPickup.map((item, index) => {
                let parsedItem = item;
                if (typeof item === 'string') {
                    try { parsedItem = JSON.parse(item); } catch(e) {}
                }
                const titleStr = typeof parsedItem === 'string' ? parsedItem : (parsedItem.number || parsedItem['AWB number'] || 'Unknown AWB');
                return `
                    <div style="display:flex; justify-content:space-between; padding: 12px; border: 1px solid #e2e8f0; border-radius: 8px; margin-bottom: 8px; background: #f8fafc;">
                        <span style="font-weight:600; font-size: 14px; color: #0f172a;"><i class="fas fa-file-alt" style="color:#64748b; margin-right:6px;"></i>${titleStr}</span>
                    </div>
                `;
            }).join('');
        }

        container.innerHTML = `
            <div style="background: white; border-radius: 16px; border: 1px solid #e2e8f0; padding: 32px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); width: 100%; max-width: 600px; margin: 0 auto; position: relative; text-align: left;">
                ${currentDriver.isPriority ? '<div style="position:absolute; top:-12px; right: 24px; background: #fef08a; color: #854d0e; padding: 6px 12px; border-radius: 20px; font-size: 12px; font-weight: 700; display:flex; align-items:center; gap:4px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"><i class="fas fa-star"></i> PRIORIDAD</div>' : ''}
                
                <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 24px;">
                    <div>
                        <div style="font-size: 12px; font-weight: 700; color: #10b981; margin-bottom: 4px; text-transform:uppercase; letter-spacing:0.5px;">Atendiendo Ahora</div>
                        <h2 style="margin: 0; font-size: 24px; color: #0f172a;">${currentDriver.driver || 'Chofer Desconocido'}</h2>
                        <div style="color: #64748b; font-size: 14px; margin-top: 4px;">Empresa: <b>${currentDriver['truck-company'] || '-'}</b></div>
                    </div>
                </div>
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 24px; background: #f1f5f9; padding: 16px; border-radius: 8px;">
                    <div>
                        <div style="font-size: 11px; color: #64748b; text-transform:uppercase; font-weight:600;">Puerta (Door)</div>
                        <div style="font-size: 16px; font-weight: 700; color: #1e293b;">${currentDriver.door || '-'}</div>
                    </div>
                    <div>
                        <div style="font-size: 11px; color: #64748b; text-transform:uppercase; font-weight:600;">ID Pickup</div>
                        <div style="font-size: 16px; font-weight: 700; color: #1e293b;">${currentDriver['id-pickup'] || '-'}</div>
                    </div>
                </div>

                <div style="margin-bottom: 32px;">
                    <h4 style="margin: 0 0 12px 0; font-size: 14px; color: #334155;">Paquetes (AWBs) a Entregar</h4>
                    ${awbsHtml}
                </div>

                <button onclick="window.confirmDriver()" style="width: 100%; padding: 16px; background: #4f46e5; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; display: flex; justify-content: center; align-items: center; gap: 8px; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.25); transition: background 0.2s;">
                    <i class="fas fa-check-circle"></i> Confirmar y Pasar al Siguiente
                </button>
            </div>
        `;
    };

    window.confirmDriver = function() {
        if (!window.activeDeliveries || window.activeDeliveries.length === 0) return;
        
        // Remove from local array sequentially
        window.activeDeliveries.shift();
        
        // Update Deliveries Table View sequentially
        const rows = document.querySelectorAll('#delivers-table-body tr');
        if (rows.length > 0 && rows[0].querySelector('td').getAttribute('colspan') !== '9') {
             rows[0].remove();
        }
        
        // Re-index remaining visual table sequences
        document.querySelectorAll('#delivers-table-body tr').forEach((r, idx) => {
            const idxTd = r.querySelector('.row-index');
            if(idxTd) idxTd.textContent = idx + 1;
        });
        
        const tbody = document.getElementById('delivers-table-body');
        if (window.activeDeliveries.length === 0 && tbody) {
             tbody.innerHTML = '<tr><td colspan="9" style="text-align:center; padding: 24px 20px; color:#94a3b8; font-style:italic; border:none; font-size: 13px;">No deliveries waiting.</td></tr>';
        }

        window.renderDriverQueue();
    };

    window.loadReadyAwbsForDelivery = async function() {
        const tableBody = document.getElementById('deliver-awb-select-body');
        tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px 20px; color:#94a3b8; font-style:italic; border: none; font-size: 13px;">Loading available AWBs...</td></tr>';
        const selectAllCb = document.getElementById('deliver-awb-select-all');
        if (selectAllCb) selectAllCb.checked = false;
        
        try {
            // Buscamos temporalmente todos los AWB para ver si tienen data-location (Saved)
            const { data, error } = await supabaseClient.from('AWB').select('*');
            if (error) throw error;
            
            tableBody.innerHTML = '';
            
            let readyAwbs = [];
            if (data) {
                data.forEach(awb => {
                     let expected = parseInt(awb.Total || awb.total || awb['cant-break'] || '0') || 0;
                     // Extraer arrays de forma segura
                     let dataAwbArr = [];
                     if (Array.isArray(awb['data-AWB'])) dataAwbArr = awb['data-AWB'];
                     else if (awb['data-AWB']) { try { dataAwbArr = JSON.parse(awb['data-AWB']); } catch(e){} }
                     
                     let dataCoordArr = [];
                     if (Array.isArray(awb['data-coordinator'])) dataCoordArr = awb['data-coordinator'];
                     else if (awb['data-coordinator']) { 
                         try { 
                             const parsed = JSON.parse(awb['data-coordinator']); 
                             if (Array.isArray(parsed)) dataCoordArr = parsed;
                         } catch(e){} 
                     }
                     
                     let dataLocArr = [];
                     if (Array.isArray(awb['data-location'])) dataLocArr = awb['data-location'];
                     else if (awb['data-location']) { try { dataLocArr = JSON.parse(awb['data-location']); } catch(e){} }

                     let received = 0;
                     let mismatchReportsText = [];
                     if (dataCoordArr.length > 0) {
                         received = dataCoordArr.reduce((acc, curr) => acc + (parseInt(curr['Total Checked']) || 0), 0);
                         dataCoordArr.forEach(curr => {
                             if (curr['Mismatch Report'] && curr['Mismatch Report'].trim() !== '') {
                                 mismatchReportsText.push(curr['Mismatch Report'].trim());
                             }
                         });
                     }

                     readyAwbs.push({
                         id: awb.id,
                         number: awb['AWB number'] || awb.awb_number || 'N/A',
                         expected: expected,
                         received: received,
                         remarks: awb.notes || '',   // Mapping 'notes' or leaving empty
                         isSaved: !!awb['data-location'],
                         originalRow: awb,
                         mismatchReportsText: mismatchReportsText
                     });
                });
            }
            
            readyAwbs.sort((a, b) => {
                const numA = (a.number || '').toString();
                const numB = (b.number || '').toString();
                return numA.localeCompare(numB);
            });
            
            if (readyAwbs.length === 0) {
                tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px 20px; color:#94a3b8; font-style:italic; border: none; font-size: 13px;">No AWBs available.</td></tr>';
                return;
            }
            
            readyAwbs.forEach((awb, index) => {
                const tr = document.createElement('tr');
                tr.style.cursor = 'pointer';
                tr.className = 'awb-hover-row'; // add a hover effect class if styling it
                tr.onmouseover = () => tr.style.background = '#f8fafc';
                tr.onmouseout = () => tr.style.background = 'transparent';
                
                tr.onclick = (e) => {
                    if (e.target.tagName === 'INPUT' && e.target.type === 'checkbox') return;
                    if (typeof window.openAwbInfoDrawer === 'function') {
                        window.openAwbInfoDrawer(awb.number, awb.expected, awb.originalRow);
                    }
                };

                const isReady = (awb.expected > 0 && awb.received === awb.expected);
                const badge = isReady 
                    ? '<div style="display:inline-flex; align-items:center; justify-content:center; background:#dcfce7; color:#166534; padding:4px 8px; border-radius:6px; font-size:11px; font-weight:700; min-width:64px;">READY</div>' 
                    : '<div style="display:inline-flex; align-items:center; justify-content:center; background:#fef3c7; color:#b45309; padding:4px 8px; border-radius:6px; font-size:11px; font-weight:700; min-width:64px;">PENDING</div>';
                    
                let mismatchHtml = '-';
                if (awb.mismatchReportsText && awb.mismatchReportsText.length > 0) {
                    const formattedReports = awb.mismatchReportsText.map((req, i) => `<b>Report ${i + 1}:</b><br>${req}`).join('<br><br>');
                    const safeReport = formattedReports.replace(/'/g, "\\'").replace(/"/g, '&quot;').replace(/\n/g, '<br>');

                    mismatchHtml = `<div title="Click to view Report" 
                        style="display:inline-flex; align-items:center; justify-content:center; background:#fee2e2; color:#b91c1c; width:22px; height:22px; border-radius:50%; font-size:11px; font-weight:bold; cursor:pointer;" 
                        onclick="event.stopPropagation(); window.viewMismatchReport('${safeReport}')">
                        ${awb.mismatchReportsText.length}
                    </div>`;
                }

                tr.innerHTML = `
                    <td style="text-align: center;"><input type="checkbox" class="deliver-awb-cb" value="${awb.id}" data-number="${awb.number}" style="accent-color: #4f46e5; width: 16px; height: 16px; cursor: pointer;"></td>
                    <td style="text-align: center; color: #94a3b8; font-size: 13px;">${index + 1}</td>
                    <td style="font-weight: 600; color: #0f172a;">${awb.number}</td>
                    <td style="text-align: center;">${mismatchHtml}</td>
                    <td style="color: #0d9488; font-weight: 500; text-align: center;">${awb.received} <span style="font-size: 11px; color:#cbd5e1;">pcs</span></td>
                    <td style="color: #64748b; font-weight: 500; text-align: center;">${awb.expected}</td>
                    <td style="text-align: center;">${badge}</td>
                `;
                tableBody.appendChild(tr);
            });
            
            // Checkbox logic
            const cbs = document.querySelectorAll('.deliver-awb-cb');
            if (selectAllCb) {
                selectAllCb.onchange = (e) => {
                    cbs.forEach(cb => cb.checked = e.target.checked);
                };
            }
            cbs.forEach(cb => {
                cb.onchange = () => {
                    if (!cb.checked && selectAllCb) selectAllCb.checked = false;
                    else if (Array.from(cbs).every(c => c.checked) && selectAllCb) selectAllCb.checked = true;
                };
            });
            
            // Search filter logic
            const searchInput = document.getElementById('deliver-awb-search');
            if (searchInput) {
                searchInput.value = ''; // clear it on load
                searchInput.addEventListener('input', function(e) {
                    const term = e.target.value.toLowerCase();
                    const rows = tableBody.querySelectorAll('tr');
                    rows.forEach(row => {
                        const awbCell = row.querySelector('td:nth-child(3)');
                        if (awbCell) {
                            const text = awbCell.textContent.toLowerCase();
                            row.style.display = text.includes(term) ? '' : 'none';
                        }
                    });
                });
            }
            
        } catch (err) {
            console.error(err);
            tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding: 24px 20px; color:#e11d48; font-size: 13px; border:none;">Error loading AWBs</td></tr>';
        }
    };
    // Generate Random 10-Char ID-Pickup
    const generateIdBtn = document.getElementById('generate-id-pickup-btn');
    if (generateIdBtn) {
        generateIdBtn.addEventListener('click', () => {
            const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
            let result = '';
            for (let i = 0; i < 10; i++) {
                result += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            document.getElementById('deliver-id-pickup').value = result;
        });
    }

    // Save Delivery
    const saveDeliverBtn = document.getElementById('save-deliver-btn');
    if (saveDeliverBtn) {
        saveDeliverBtn.addEventListener('click', async () => {
            const drName = document.getElementById('deliver-driver').value.trim();
            const idPickup = document.getElementById('deliver-id-pickup').value.trim();
            const truckCompany = document.getElementById('deliver-truck-company').value.trim();
            const door = document.getElementById('deliver-door').value.trim();
            const delivType = document.getElementById('deliver-type').value;
            const remarks = document.getElementById('deliver-remarks').value;
            
            const isPriorityEl = document.getElementById('deliver-is-priority');
            const isPriority = isPriorityEl ? isPriorityEl.checked : false;
            
            const selectedCbs = document.querySelectorAll('.deliver-awb-cb:checked');
            
            if (!truckCompany) {
                return window.showValidationModal('Missing Information', 'Company is required.');
            }
            if (!drName) {
                return window.showValidationModal('Missing Information', 'Driver Name is required.');
            }
            if (!door) {
                return window.showValidationModal('Missing Information', 'Door is required.');
            }
            if (!idPickup) {
                return window.showValidationModal('Missing Information', 'ID-Pickup is required.');
            }
            if (selectedCbs.length === 0) {
                return window.showValidationModal('No AWBs Selected', 'Please select at least one AWB to deliver.');
            }
            
            const selectedAwbs = Array.from(selectedCbs).map(cb => {
                const tr = cb.closest('tr');
                const tds = tr.querySelectorAll('td');
                return {
                    number: cb.getAttribute('data-number'),
                    totalExpected: tds[3] ? tds[3].textContent : '0',
                    totalReceived: tds[4] ? tds[4].textContent : '0',
                    // Default to '-' as there is no specific field in this view forflight/pallets
                    flight: '-', 
                    pallet: '-'  
                };
            });
            
            saveDeliverBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
            saveDeliverBtn.disabled = true;
            
            try {
                const payload = {
                    'truck-company': truckCompany,
                    driver: drName,
                    door: door,
                    'id-pickup': idPickup,
                    'list-pickup': selectedAwbs,
                    isPriority: isPriority,
                    type: delivType,
                    remarks: remarks
                };
                
                const { error } = await supabaseClient.from('Delivers').insert([payload]);
                
                // Ignoramos error si no existe la tabla
                if (error && error.code !== '42P01') { 
                    throw error;
                } else if (error && error.code === '42P01') {
                    console.warn("Table 'Delivers' does not exist. Payload would be:", payload);
                    window.showValidationModal("Table Missing", "Aviso: La tabla 'Delivers' no existe aún en Supabase, pero la interfaz está lista para conectarse cuando la crees.");
                } else {
                    // SUCCESS OVERLAY
                    const overlay = document.createElement('div');
                    overlay.style.cssText = `
                        position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
                        background: rgba(255, 255, 255, 0.85); z-index: 99999;
                        display: flex; align-items: center; justify-content: center;
                        backdrop-filter: blur(4px); opacity: 0; transition: opacity 0.3s ease;
                    `;
                    overlay.innerHTML = `
                        <div style="background: white; padding: 32px 48px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); display: flex; flex-direction: column; align-items: center; gap: 16px; transform: scale(0.9); transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);">
                            <div style="width: 64px; height: 64px; background: #10b981; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
                                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <polyline points="20 6 9 17 4 12"></polyline>
                                </svg>
                            </div>
                            <h2 style="margin: 0; color: #0f172a; font-size: 20px; font-weight: 700;">¡Guardado!</h2>
                            <p style="margin: 0; color: #64748b; font-size: 14px;">El delivery ha sido registrado con éxito.</p>
                        </div>
                    `;
                    document.body.appendChild(overlay);

                    // Animate in
                    requestAnimationFrame(() => {
                        overlay.style.opacity = '1';
                        overlay.firstElementChild.style.transform = 'scale(1)';
                    });

                    await new Promise(r => setTimeout(r, 1200));

                    // Animate out and remove
                    overlay.style.opacity = '0';
                    overlay.firstElementChild.style.transform = 'scale(0.9)';
                    setTimeout(() => overlay.remove(), 300);
                }
                
                document.getElementById('deliver-truck-company').value = '';
                document.getElementById('deliver-driver').value = '';
                document.getElementById('deliver-door').value = '';
                document.getElementById('deliver-id-pickup').value = '';
                document.getElementById('deliver-remarks').value = '';
                document.getElementById('deliver-type').value = 'Normal';
                
                document.getElementById('back-to-delivers-btn').click();
                
            } catch (err) {
                console.error(err);
                window.showValidationModal("Failed to save delivery", err.message);
            } finally {
                saveDeliverBtn.innerHTML = '<i class="fas fa-save"></i> Save Delivery';
                saveDeliverBtn.disabled = false;
            }
        });
    }

    // --- SUPABASE REALTIME SUBSCRIPTIONS ---
    const realtimeChannel = supabaseClient.channel('schema-db-changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'Flight' }, (payload) => {
            console.log('Realtime [Flight]:', payload);
            if (typeof window.fetchFlights === 'function') window.fetchFlights();
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'flights' }, (payload) => {
            console.log('Realtime [flights]:', payload);
            if (typeof window.fetchFlights === 'function') window.fetchFlights();
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'ULD' }, (payload) => {
            console.log('Realtime [ULD]:', payload);
            if (typeof window.fetchGlobalUlds === 'function') window.fetchGlobalUlds();
            if (typeof window.fetchFlights === 'function') window.fetchFlights(); 
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'AWB' }, (payload) => {
            console.log('Realtime [AWB]:', payload);
            if (typeof window.fetchGlobalAwbs === 'function') window.fetchGlobalAwbs();
            // AWB changes might affect Flight lists visually in some setups
            if (typeof window.fetchFlights === 'function') window.fetchFlights();
        })
        .subscribe((status) => {
            console.log('Supabase Realtime Subscription Status:', status);
        });

    window.currentSelectedFlightForReports = null;

    window.checkFlightReadyStatus = function() {
        const coordCheckBtn = document.getElementById('coord-check-flight-btn');
        if (!coordCheckBtn) return;
        if (coordCheckBtn.textContent === 'CHECKED') return;

        let uldsAllChecked = false;
        const coordTbody = document.getElementById('coord-ulds');
        if (coordTbody) {
            const allBtns = Array.from(coordTbody.querySelectorAll('.coord-uld-check-btn'));
            uldsAllChecked = allBtns.length > 0 && allBtns.every(b => {
                const status = b.getAttribute('data-status');
                return status === 'Checked' || status === 'Chequeado' || status === 'Ready';
            });
        }

        let discrepanciesAllResolved = true;
        if (window.currentDiscrepanciesList && window.currentDiscrepanciesList.length > 0) {
            window.currentDiscrepanciesList.forEach((d, index) => {
                const safeIdPart = d.awb.replace(/[^a-zA-Z0-9]/g, '');
                const btn = document.getElementById(`verify-btn-${safeIdPart}-${index}`);
                const noteBtn = document.getElementById(`add-note-btn-${safeIdPart}-${index}`);
                
                if (!btn) {
                     discrepanciesAllResolved = false;
                     return;
                }
                const html = btn.innerHTML;
                const text = btn.textContent;
                let isGood = html.includes('fa-check') || text.includes('Good') || text.includes('GOOD');
                
                let isNote = false;
                if (noteBtn && (noteBtn.innerHTML.includes('fa-sticky-note') || noteBtn.textContent.trim().toUpperCase() === 'NOTE' || noteBtn.textContent.trim() === 'Note')) {
                     if (noteBtn.style.display !== 'none') isNote = true;
                }
                if (btn.style.display === 'none') {
                     isNote = true;
                }
                
                if (!isGood && !isNote) {
                    discrepanciesAllResolved = false;
                }
            });
        }

        if (uldsAllChecked && discrepanciesAllResolved) {
            coordCheckBtn.disabled = false;
            coordCheckBtn.style.opacity = '1';
            coordCheckBtn.style.cursor = 'pointer';
        } else {
            coordCheckBtn.disabled = true;
            coordCheckBtn.style.opacity = '0.5';
            coordCheckBtn.style.cursor = 'not-allowed';
        }
    };

    window.checkLocFlightReadyStatus = function() {
        const locReadyBtn = document.getElementById('loc-ready-flight-btn');
        if (!locReadyBtn) return;
        if (locReadyBtn.textContent === 'READY') return;

        let uldsAllReady = false;
        const locTbody = document.getElementById('loc-ulds');
        if (locTbody) {
            const allBtns = Array.from(locTbody.querySelectorAll('.coord-uld-check-btn'));
            uldsAllReady = allBtns.length > 0 && allBtns.every(b => {
                const status = b.getAttribute('data-status');
                return status === 'Ready' || status === 'Listo';
            });
        }

        if (uldsAllReady) {
            locReadyBtn.disabled = false;
            locReadyBtn.style.opacity = '1';
            locReadyBtn.style.cursor = 'pointer';
        } else {
            locReadyBtn.disabled = true;
            locReadyBtn.style.opacity = '0.5';
            locReadyBtn.style.cursor = 'not-allowed';
        }
    };

    window.checkIfAllDiscrepanciesResolved = function() {
        if (!window.currentDiscrepanciesList || window.currentDiscrepanciesList.length === 0) return;
        
        let isComplete = true;
        window.currentDiscrepanciesList.forEach((d, index) => {
            const safeIdPart = d.awb.replace(/[^a-zA-Z0-9]/g, '');
            const btn = document.getElementById(`verify-btn-${safeIdPart}-${index}`);
            const noteBtn = document.getElementById(`add-note-btn-${safeIdPart}-${index}`);
            
            if (!btn) {
                 isComplete = false;
                 return;
            }
            const html = btn.innerHTML;
            const text = btn.textContent;
            let isGood = html.includes('fa-check') || text.includes('Good') || text.includes('GOOD');
            
            let isNote = false;
            // Check if note is properly added via UI display state or icon
            if (noteBtn && (noteBtn.innerHTML.includes('fa-sticky-note') || noteBtn.textContent.trim().toUpperCase() === 'NOTE' || noteBtn.textContent.trim() === 'Note')) {
                 // Check if it's actually visible or if it's the verified state showing it
                 if (noteBtn.style.display !== 'none') {
                     isNote = true;
                 }
            }
            if (btn.style.display === 'none') {
                 // If verify button was explicitly hidden, it means "Note" totally took over.
                 isNote = true;
            }
            
            if (!isGood && !isNote) {
                isComplete = false;
            }
        });

        const verifyAllBtn = document.getElementById('drawer-verify-all-btn');
        const outerBtn = document.getElementById('coord-flight-reports-btn');

        const coordCheckBtn = document.getElementById('coord-check-flight-btn');
        let isFlightChecked = false;
        
        if (window.currentSelectedFlightForReports) {
            isFlightChecked = window.currentSelectedFlightForReports.status === 'Checked' || window.currentSelectedFlightForReports.status === 'Chequeado';
        } else if (coordCheckBtn) {
            isFlightChecked = coordCheckBtn.textContent === 'CHECKED';
        }

        if (isComplete) {
            if (verifyAllBtn) {
                if (isFlightChecked) {
                    verifyAllBtn.style.display = 'none';
                } else {
                    verifyAllBtn.style.display = 'flex';
                    verifyAllBtn.innerHTML = '<i class="fas fa-check"></i> Listo';
                    verifyAllBtn.style.background = '#10b981';
                    verifyAllBtn.onclick = window.submitAllFlightReportsToDB;
                }
            }
            if (outerBtn) {
                outerBtn.innerHTML = '<i class="fas fa-check-circle"></i> Verified';
                outerBtn.style.background = '#f0fdf4';
                outerBtn.style.color = '#16a34a';
                outerBtn.style.borderColor = '#bbf7d0';
                outerBtn.setAttribute('onmouseover', "this.style.background='#dcfce7'");
                outerBtn.setAttribute('onmouseout', "this.style.background='#f0fdf4'");
            }
        } else {
            if (verifyAllBtn) {
                if (isFlightChecked) {
                    verifyAllBtn.style.display = 'none';
                } else {
                    verifyAllBtn.style.display = 'flex';
                    verifyAllBtn.innerHTML = '<i class="fas fa-clipboard-check"></i> Verify All Anomalies';
                    verifyAllBtn.style.background = '#0f172a';
                    verifyAllBtn.onclick = window.runAllAwbInventoryChecks;
                }
            }
            if (outerBtn && !outerBtn.disabled) {
                const count = (window.currentDiscrepanciesList) ? window.currentDiscrepanciesList.length : 0;
                outerBtn.innerHTML = `<i class="fas fa-exclamation-triangle"></i> Discrepancies <span id="coord-flight-reports-badge" style="background:#e11d48; color:white; border-radius:12px; padding:2px 6px; font-size:10px; margin-left:4px;">${count}</span>`;
                outerBtn.style.background = '#fff1f2';
                outerBtn.style.color = '#e11d48';
                outerBtn.style.borderColor = '#fecaca';
                outerBtn.setAttribute('onmouseover', "this.style.background='#ffe4e6'");
                outerBtn.setAttribute('onmouseout', "this.style.background='#fff1f2'");
            }
        }
        
        window.checkFlightReadyStatus();
    };

    window.refreshFlightDiscrepancies = async function(flight) {
        if (!flight) return;
        window.currentSelectedFlightForReports = flight;
        
        const btn = document.getElementById('coord-flight-reports-btn');
        const badge = document.getElementById('coord-flight-reports-badge');
        const listBody = document.getElementById('flight-reports-list');
        const subtitle = document.getElementById('flight-reports-drawer-subtitle');
        
        if (!btn) return;

        try {
            const { data: flightAwbs, error: awbErr } = await supabaseClient.from('AWB').select('*');
            if (awbErr) throw awbErr;
            
            // Also fetch current flight to get the `report` JSON array
            let flightRes = await supabaseClient.from('Flight').select('report').eq('id', flight.id).single();
            if (flightRes.error) {
                flightRes = await supabaseClient.from('flights').select('report').eq('id', flight.id).single();
            }
            const flightDoc = flightRes.data;
            let flightReportsArray = [];
            if (flightDoc && Array.isArray(flightDoc.report)) {
                flightReportsArray = flightDoc.report;
            } else if (flightDoc && flightDoc.report) {
                try {
                    let parsed = JSON.parse(flightDoc.report);
                    if (Array.isArray(parsed)) flightReportsArray = parsed;
                } catch(e) {}
            }
            
            let discrepancies = [];
            
            flightAwbs.forEach(awbDoc => {
                let coordArr = [];
                if (Array.isArray(awbDoc['data-coordinator'])) coordArr = awbDoc['data-coordinator'];
                else if (awbDoc['data-coordinator']) { 
                    try { coordArr = JSON.parse(awbDoc['data-coordinator']); } catch(e){} 
                }
                
                if (Array.isArray(coordArr)) {
                    coordArr.forEach(c => {
                        const expectedCarrier = String(flight.carrier || '').trim().toLowerCase();
                        const expectedNumber = String(flight.number || '').trim().toLowerCase();
                        let expectedDate = flight.date ? flight.date.split('T')[0] : '';
                        if(!expectedDate && flight.arrival_date) expectedDate = flight.arrival_date.split('T')[0];
                        if(!expectedDate && flight['date-arrived']) expectedDate = flight['date-arrived'].split('T')[0];

                        const sameFlight = 
                            String(c.refCarrier || '').trim().toLowerCase() === expectedCarrier &&
                            String(c.refNumber || '').trim().toLowerCase() === expectedNumber &&
                            expectedDate && String(c.refDate || '').trim().toLowerCase().includes(expectedDate);

                        if (sameFlight && c['Mismatch Report'] && c['Mismatch Report'].trim() !== '') {
                            const uldName = c.refULD || 'UNKNOWN';
                            const awbName = c.awbNumber || awbDoc['AWB number'] || awbDoc.number || 'UNKNOWN';
                            const rText = c['Mismatch Report'].trim();
                            
                            // Add only if not a strict duplicate in memory
                            const isDup = discrepancies.find(dx => dx.uld === uldName && dx.awb === awbName && dx.report === rText);
                            if(!isDup) {
                                let pieces = 0, weight = 0, remarks = '-', houses = '';
                                let encodedData = encodeURIComponent(JSON.stringify(c));
                                let encodedLocs = '';
                                
                                let locArr = [];
                                if (Array.isArray(awbDoc['data-location'])) locArr = awbDoc['data-location'];
                                else if (awbDoc['data-location']) { 
                                    try { locArr = JSON.parse(awbDoc['data-location']); } catch(e){} 
                                }
                                if (Array.isArray(locArr)) {
                                    const locObj = locArr.find(l => l.refULD === uldName && l.refCarrier === c.refCarrier && l.refNumber === c.refNumber && l.refDate === c.refDate);
                                    if(locObj) encodedLocs = encodeURIComponent(JSON.stringify(locObj));
                                }

                                let nestedArr = [];
                                if (Array.isArray(awbDoc['data-AWB'])) nestedArr = awbDoc['data-AWB'];
                                else if (awbDoc['data-AWB']) {
                                    try { nestedArr = JSON.parse(awbDoc['data-AWB']); } catch(e){}
                                }
                                if (Array.isArray(nestedArr)) {
                                    const nestedData = nestedArr.find(n => n.refULD === uldName && n.refCarrier === c.refCarrier && n.refNumber === c.refNumber && n.refDate === c.refDate);
                                    if(nestedData) {
                                        pieces = nestedData.pieces || 0;
                                        weight = nestedData.weight || 0;
                                        remarks = nestedData.remarks || '-';
                                        houses = (nestedData.house_number || []).join(', ');
                                    }
                                }

                                let breakdownHtml = `<div id="breakdown-${awbName.replace(/[^a-zA-Z0-9]/g, '')}-` + discrepancies.length + `" class="discrepancy-breakdown" style="display: none; margin-top: 12px; padding-top: 12px; border-top: 1px solid #e2e8f0; font-size: 11px; color: #475569;">
                                    <div style="font-weight: 600; margin-bottom: 6px; color: #0f172a;">Pieces Breakdown:</div>`;

                                let totalExpAll = 0;
                                let totalRecAll = 0;

                                if (Array.isArray(coordArr)) {
                                    coordArr.forEach(c2 => {
                                        const sameFlight2 = 
                                            String(c2.refCarrier || '').trim().toLowerCase() === expectedCarrier &&
                                            String(c2.refNumber || '').trim().toLowerCase() === expectedNumber &&
                                            expectedDate && String(c2.refDate || '').trim().toLowerCase().includes(expectedDate);
                                            
                                        if (sameFlight2) {
                                            let expPcs = 0;
                                            if (Array.isArray(nestedArr)) {
                                                let nData = nestedArr.find(n => n.refULD === c2.refULD && n.refCarrier === c2.refCarrier && n.refNumber === c2.refNumber && n.refDate === c2.refDate);
                                                if (nData) expPcs = parseInt(nData.pieces) || 0;
                                            }
                                            
                                            let sumFields = 0;
                                            ['Agi skid', 'Pre skid', 'Crates', 'Box', 'Other'].forEach(key => {
                                                let val = c2[key] || c2[key.toLowerCase()];
                                                if (Array.isArray(val)) {
                                                    sumFields += val.reduce((acc, curr) => acc + (parseInt(curr) || 0), 0);
                                                } else {
                                                    sumFields += (parseInt(val) || 0);
                                                }
                                            });
                                            
                                            if (c2.refULD === 'UNKNOWN' && sumFields === 0 && expPcs === 0) return; // avoid empty dummy
                                            
                                            totalExpAll += expPcs;
                                            totalRecAll += sumFields;
                                            
                                            breakdownHtml += `<div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
                                                <span>ULD: ${c2.refULD || 'UNKNOWN'}</span>
                                                <span>Expected: ${expPcs} | Received: <b>${sumFields}</b></span>
                                            </div>`;
                                        }
                                    });
                                }
                                breakdownHtml += `<div style="display: flex; justify-content: space-between; margin-top: 6px; padding-top: 6px; border-top: 1px dashed #cbd5e1; font-weight: 700; color: #0f172a;">
                                    <span>TOTAL</span>
                                    <span>Expected: ${totalExpAll} | Received: ${totalRecAll}</span>
                                </div></div>`;

                                discrepancies.push({ 
                                    uld: uldName, 
                                    awb: awbName, 
                                    report: rText,
                                    awbId: awbDoc.id,
                                    tot: awbDoc.total || 0,
                                    wgt: weight,
                                    hse: houses,
                                    rem: remarks.replace(/'/g, "\\'").replace(/"/g, '&quot;'),
                                    note: (flightReportsArray.find(r => r.awb === awbName && r.uld === uldName)?.note || '').replace(/'/g, "\\'").replace(/"/g, '&quot;'),
                                    rCarrier: c.refCarrier,
                                    rNum: c.refNumber,
                                    rDate: c.refDate,
                                    encodedData,
                                    encodedLocs,
                                    breakdownHtml
                                });
                            }
                        }
                    });
                }
            });
            
            if (discrepancies.length > 0) {
                const resolvedFlight = flight || window.currentSelectedFlightForReports || {};
                const isFlightChecked = resolvedFlight.status === 'Checked' || resolvedFlight.status === 'Chequeado';

                if (isFlightChecked) {
                    btn.style.display = 'flex';
                    btn.innerHTML = '<i class="fas fa-check-circle"></i> Verified';
                    btn.style.background = '#f0fdf4';
                    btn.style.color = '#16a34a';
                    btn.style.borderColor = '#bbf7d0';
                    btn.setAttribute('onmouseover', "this.style.background='#dcfce7'");
                    btn.setAttribute('onmouseout', "this.style.background='#f0fdf4'");
                    btn.disabled = false;
                    btn.style.opacity = '1';
                    btn.style.cursor = 'pointer';
                } else {
                    btn.style.display = 'flex';
                    btn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Discrepancies <span id="coord-flight-reports-badge" style="background:#e11d48; color:white; border-radius:12px; padding:2px 6px; font-size:10px; margin-left:4px;">' + discrepancies.length + '</span>';
                    btn.style.background = '#fff1f2';
                    btn.style.color = '#e11d48';
                    btn.style.borderColor = '#fecaca';
                    btn.setAttribute('onmouseover', "this.style.background='#ffe4e6'");
                    btn.setAttribute('onmouseout', "this.style.background='#fff1f2'");
                    btn.disabled = false;
                    btn.style.opacity = '1';
                    btn.style.cursor = 'pointer';
                }
            } else {
                btn.style.display = 'flex';
                btn.innerHTML = '<i class="fas fa-exclamation-triangle"></i> Discrepancies <span id="coord-flight-reports-badge" style="background:#e11d48; color:white; border-radius:12px; padding:2px 6px; font-size:10px; margin-left:4px;">0</span>';
                btn.style.background = '#fff1f2';
                btn.style.color = '#e11d48';
                btn.style.borderColor = '#fecaca';
                btn.onmouseover = null;
                btn.onmouseout = null;
                btn.disabled = true;
                btn.style.opacity = '0.5';
                btn.style.cursor = 'not-allowed';
            }
            window.currentDiscrepanciesList = discrepancies;
            const verifyAllBtn = document.getElementById('drawer-verify-all-btn');
            if(verifyAllBtn) {
                if (discrepancies.length > 0) {
                    verifyAllBtn.disabled = false;
                    verifyAllBtn.style.opacity = '1';
                    verifyAllBtn.style.cursor = 'pointer';
                } else {
                    verifyAllBtn.disabled = true;
                    verifyAllBtn.style.opacity = '0.5';
                    verifyAllBtn.style.cursor = 'not-allowed';
                }
            }
            
            if (subtitle) {
                subtitle.textContent = `Flight ${flight.carrier || ''}${flight.number || ''} - ${discrepancies.length} reports`;
            }
            
            if (listBody) {
                if (discrepancies.length === 0) {
                    listBody.innerHTML = '<div style="text-align:center; padding: 32px 16px; color:#94a3b8; font-style:italic;">No discrepancies generated for this flight thus far.</div>';
                } else {
                    listBody.innerHTML = discrepancies.map((d, index) => {
                        let cleanReport = d.report.replace(/\n/g, '<br>');
                        if (cleanReport.startsWith(`AWB ${d.awb}: `)) {
                            cleanReport = cleanReport.substring(`AWB ${d.awb}: `.length);
                        }
                        
                        let iconHtml = '<i class="fas fa-exclamation-triangle" style="margin-right: 6px;"></i>';
                        let boxStyle = "background: #fff1f2; color:#e11d48; padding: 10px; border-radius: 6px; font-size: 13px; font-weight: 500; border: 1px dashed #fda4af;";
                        
                        if (d.report.includes('OVER')) {
                            iconHtml = '<i class="fas fa-plus-circle" style="margin-right: 6px; font-size: 14px;"></i>';
                            boxStyle = "background: #f3e8ff; color:#7e22ce; padding: 10px; border-radius: 6px; font-size: 13px; font-weight: 500; border: 1px dashed #d8b4fe;";
                        } else if (d.report.includes('SHORT')) {
                            iconHtml = '<i class="fas fa-minus-circle" style="margin-right: 6px; font-size: 14px;"></i>';
                            boxStyle = "background: #fef2f2; color:#b91c1c; padding: 10px; border-radius: 6px; font-size: 13px; font-weight: 500; border: 1px dashed #fca5a5;";
                        }
                        
                        const safeHStr = (d.hse || '').replace(/'/g, "\\'").replace(/"/g, '&quot;');
                        
                        // Fix 1: The correct reference for the current flight in this context is 'flight' not window.currentSelectedFlightForReports but we can use both
                        const resolvedFlight = flight || window.currentSelectedFlightForReports || {};
                        const isFlightChecked = resolvedFlight.status === 'Checked' || resolvedFlight.status === 'Chequeado';
                        let buttonHtml = `<div style="position: absolute; bottom: 16px; right: 16px; display: flex; gap: 12px; align-items: center;">`;

                        if (!isFlightChecked) {
                            if (d.note) {
                                // Has note means it's already verified as BAD and stored. Only show Note.
                                buttonHtml += `
                                <button id="add-note-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" onclick="event.stopPropagation(); window.openDiscrepancyDetailModal(${index});" style="background: transparent; border: none; color: #3b82f6; cursor: pointer; align-items: center; gap: 4px; font-size: 14px; font-weight: 600;" title="View Note"><i class="fas fa-sticky-note" style="font-size: 14px;"></i> Note</button>
                                `;
                                
                                // Hidden verify button so we don't break logic that looks for it
                                buttonHtml += `<span id="verify-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" style="display: none;"></span>`;
                            } else {
                                // No note: Hidden "Add Note" button until it turns Bad
                                buttonHtml += `<button id="add-note-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" onclick="event.stopPropagation(); window.openDiscrepancyDetailModal(${index});" style="display: none; background: transparent; border: none; color: #3b82f6; cursor: pointer; align-items: center; gap: 4px; font-size: 12px; font-weight: 600;" title="Add Note"><i class="fas fa-comment-dots" style="font-size: 14px;"></i> Add Note</button>`;

                                buttonHtml += `
                                <button id="verify-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" onclick="event.stopPropagation(); window.runAwbInventoryCheck('${d.awb}', false, ${index})" style="background: transparent; border: none; color: #475569; cursor: pointer; display: flex; align-items: center; gap: 4px; font-size: 11px; font-weight: 600; transition: color 0.2s;" onmouseover="this.style.color='#0f172a'" onmouseout="this.style.color='#475569'" title="Verify Pieces">
                                    <i class="fas fa-search" style="font-size: 14px;"></i> Verify
                                </button>
                                `;
                            }
                            
                        } else {
                            // Flight is Checked
                            if (d.note) {
                                buttonHtml += `
                                <button id="add-note-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" onclick="event.stopPropagation(); window.openDiscrepancyDetailModal(${index});" style="background: transparent; border: none; color: #3b82f6; cursor: pointer; display: flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 600;" title="View Note">
                                    <i class="fas fa-sticky-note" style="font-size: 14px;"></i> Note
                                </button>
                                `;
                                buttonHtml += `<span id="verify-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" style="color: #ef4444; display: flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 600;"><i class="fas fa-times-circle" style="font-size: 14px;"></i> Bad</span>`;
                            } else {
                                buttonHtml += `<span id="verify-btn-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}" style="color: #10b981; display: flex; align-items: center; gap: 4px; font-size: 14px; font-weight: 600;"><i class="fas fa-check-circle" style="font-size: 14px;"></i> Good</span>`;
                            }
                        }
                        
                        buttonHtml += `</div>`;

                        return `
                        <div style="background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; padding-bottom: 44px; margin-bottom: 8px; position: relative; cursor: pointer; transition: all 0.2s;" onmouseover="this.style.boxShadow='0 4px 6px rgba(0,0,0,0.05)'; this.style.borderColor='#cbd5e1';" onmouseout="this.style.boxShadow='none'; this.style.borderColor='#e2e8f0';" onclick="const bd = document.getElementById('breakdown-${d.awb.replace(/[^a-zA-Z0-9]/g, '')}-${index}'); if(bd) bd.style.display = (bd.style.display === 'none' ? 'block' : 'none');">
                            <div style="display:flex; justify-content:space-between; margin-bottom: 8px;">
                                <span style="font-weight:700; color:#0f172a; font-size:13px;"><i class="fas fa-pallet"></i> ULD: ${d.uld}</span>
                                <span style="font-weight:600; color:#64748b; font-size:12px;">AWB: ${d.awb}</span>
                            </div>
                            <div style="${boxStyle}">
                                <div style="display:flex; align-items:flex-start;">
                                    <div style="margin-top:2px;">${iconHtml}</div>
                                    <div>${cleanReport}</div>
                                </div>
                            </div>
                            
                            <!-- Appended Breakdown HTML, hidden by default, toggled by clicking the container -->
                            ${d.breakdownHtml}
                            
                            ${buttonHtml}
                        </div>
                    `;
                    }).join('');
                }
            }
            
            setTimeout(window.checkIfAllDiscrepanciesResolved, 150);
        } catch (e) {
            console.warn("Failed to refresh real-time flight discrepancies:", e);
        }
    };

    window.openDiscrepancyDetailModal = function(index) {
        const d = (window.currentDiscrepanciesList || [])[index];
        if(!d) return;

        const { awbId, awb, pcs, tot, rDate, report, note, uld } = d;
        let exNote = note || '';
        let uldName = uld || '';
        let rawReport = report || '';

        document.getElementById('discrepancy-detail-title').textContent = `Discrepancy AWB: ${awb}`;
        document.getElementById('discrepancy-detail-subtitle').textContent = `Reported on ${rDate || 'Unknown Date'}`;
        
        let expected = parseInt(tot, 10) || 0;
        document.getElementById('discrepancy-expected-pcs').textContent = expected;
        
        let received = parseInt(pcs, 10) || 0;
        const match = report.match(/([0-9]+)\s*piece\(s\)\s*(SHORT|OVER)/i);
        if (match) {
            const diff = parseInt(match[1], 10) || 0;
            const type = match[2].toUpperCase();
            if (type === 'SHORT') received = expected - diff;
            if (type === 'OVER') received = expected + diff;
        }
        
        document.getElementById('discrepancy-received-pcs').textContent = received;
        let noteField = document.getElementById('discrepancy-resolution-text');
        
        // Un-escape the note safely before putting it in textarea value
        let decodedNote = exNote.replace(/&quot;/g, '"').replace(/\\'/g, "'");
        noteField.value = decodedNote;
        
        const noteContainer = document.getElementById('discrepancy-resolution-text').parentElement;
        const saveBtnContainer = document.getElementById('discrepancy-save-btn').parentElement;
        
        // We know they clicked either "Add Note" or "Note", so we can safely assume they intend to see/edit notes here.
        // There's no scenario where a Good item would let them open this modal anymore since the row no longer has click events opening it.
        noteContainer.style.display = 'flex';
        saveBtnContainer.style.display = 'flex';
        
        // Update the button string to reflect whether we are adding or updating
        const saveBtn = document.getElementById('discrepancy-save-btn');
        if (saveBtn) {
            saveBtn.innerHTML = decodedNote ? 'Update Note' : 'Save Note';
        }
        
        // Setup a global variable for when we want to save this later
        window.currentDiscrepancyResolutionContext = { index, awbId, awb, expected, received, uldName, rawReport };
        
        document.getElementById('discrepancy-detail-modal-overlay').classList.add('open');
        document.getElementById('discrepancy-detail-modal').classList.add('open');
    };

    window.saveDiscrepancyNote = async function() {
        if (!window.currentDiscrepancyResolutionContext || !window.currentSelectedFlightForReports) return;
        const { index, awbId, awb, uldName, rawReport, expected, received } = window.currentDiscrepancyResolutionContext;
        const flightId = window.currentSelectedFlightForReports.id;
        const textArea = document.getElementById('discrepancy-resolution-text');
        const text = textArea ? textArea.value.trim() : '';
        
        if (!text) {
           window.showValidationModal('Validation Error', 'Please enter a note before saving.');
           return;
        }

        const btn = document.getElementById('discrepancy-save-btn');
        if (btn) {
            btn.disabled = true;
        }

        try {
            // Keep local memory up to date
            if(window.currentDiscrepanciesList && typeof index === 'number') {
                const targetD = window.currentDiscrepanciesList[index];
                if(targetD) {
                    targetD.note = text.replace(/'/g, "\\'").replace(/"/g, '&quot;');
                    // Ensure we save expected and received locally when note is added just in case
                    if(targetD.expected === undefined) targetD.expected = expected;
                    if(targetD.received === undefined) targetD.received = received;
                }
            }

            // Change badge in UI for exactly the clicked item
            const safeIdPart = awb.replace(/[^a-zA-Z0-9]/g, '');
            const specificVerifyBtn = document.getElementById(`verify-btn-${safeIdPart}-${index}`);
            const specificAddNoteBtn = document.getElementById(`add-note-btn-${safeIdPart}-${index}`);

            if (specificVerifyBtn) {
                specificVerifyBtn.style.display = 'none'; // REMOVE the Bad!
            }
            
            if (specificAddNoteBtn) {
                specificAddNoteBtn.style.display = 'flex';
                specificAddNoteBtn.innerHTML = '<i class="fas fa-sticky-note" style="font-size: 14px;"></i> Note';
                specificAddNoteBtn.style.fontSize = '14px';
                specificAddNoteBtn.style.cursor = 'pointer';
                specificAddNoteBtn.title = 'View Note';
                // Note: The onclick event remains openDiscrepancyDetailModal(index)
            }
            
            // We intentionally skip re-listing it here because we did it above
            window.checkIfAllDiscrepanciesResolved();

            document.getElementById('discrepancy-detail-modal').classList.remove('open');
            document.getElementById('discrepancy-detail-modal-overlay').classList.remove('open');
        } catch (e) {
            console.error("Failed to save discrepancy note:", e);
            window.showValidationModal('Save Error', 'Failed to save note: ' + (e.message || 'Unknown error'));
        } finally {
            if (btn) {
                btn.innerHTML = 'Save Note';
                btn.disabled = false;
            }
        }
    };

    window.openFlightReportsDrawer = function() {
        if(document.getElementById('coord-flight-reports-btn').disabled) return;
        document.getElementById('flight-reports-drawer-overlay').classList.add('open');
        document.getElementById('flight-reports-drawer').style.right = '0';
    };

    window.closeFlightReportsDrawer = function() {
        document.getElementById('flight-reports-drawer-overlay').classList.remove('open');
        document.getElementById('flight-reports-drawer').style.right = '-100%';
    };

    window.submitAllFlightReportsToDB = async function() {
        // Collect discrepancies and save to DB
        if (!window.currentSelectedFlightForReports) return;
        const btn = document.getElementById('drawer-verify-all-btn');
        if (btn) {
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Guardando...';
            btn.disabled = true;
        }

        try {
            const flightId = window.currentSelectedFlightForReports.id;
            let fTable = 'Flight';
            
            // Build the updated reports array for the DB
            let finalReports = window.currentDiscrepanciesList.map(d => ({
                awb: d.awb,
                uld: d.uld,
                expected: d.expected !== undefined ? d.expected : (d.tot ? parseInt(d.tot) : 0),
                received: d.received !== undefined ? d.received : 0, 
                date: new Date().toISOString(),
                note: d.note || ''
            }));
            
            const { error: fErr } = await supabaseClient.from(fTable).update({
                report: finalReports
            }).eq('id', flightId);
            
            if (fErr) {
                const retry = await supabaseClient.from('flights').update({ report: finalReports }).eq('id', flightId);
                if (retry.error) throw retry.error;
            }

            window.closeFlightReportsDrawer();
            
        } catch (e) {
            console.error("Error submitting reports:", e);
            window.showValidationModal("Save Error", "Could not save reports: " + e.message);
        } finally {
            if (btn) {
                btn.innerHTML = '<i class="fas fa-check"></i> Listo';
                btn.disabled = false;
            }
        }
    };

    window.runAwbInventoryCheck = async function(awbNumber, hideAlert = false, index = null) {
        if (!awbNumber) return { ok: false, error: 'No awb number' };
        
        const safeIdPart = awbNumber.replace(/[^a-zA-Z0-9]/g, '');
        let btnInstances = [];
        if (index !== null) {
            const specificBtn = document.getElementById(`verify-btn-${safeIdPart}-${index}`);
            if (specificBtn) btnInstances.push(specificBtn);
        } else {
            btnInstances = document.querySelectorAll(`[id^="verify-btn-${safeIdPart}-"]`);
        }
        
        try {
            const { data: awbDoc, error } = await supabaseClient.from('AWB').select('*').eq('AWB number', awbNumber).single();
            if (error || !awbDoc) throw new Error("AWB not found in database.");

            let totalExpected = parseInt(awbDoc.total) || parseInt(awbDoc.pieces) || 0;
            let totalCheckedDataCoord = 0;
            
            let coordArr = [];
            if (Array.isArray(awbDoc['data-coordinator'])) coordArr = awbDoc['data-coordinator'];
            else if (awbDoc['data-coordinator']) { 
                try { coordArr = JSON.parse(awbDoc['data-coordinator']); } catch(e){} 
            }
            
            if (Array.isArray(coordArr)) {
                coordArr.forEach(c => {
                    let sumFields = 0;
                    ['Agi skid', 'Pre skid', 'Crates', 'Box', 'Other'].forEach(key => {
                        let val = c[key] || c[key.toLowerCase()]; // Fallback if saved differently
                        if (Array.isArray(val)) {
                            sumFields += val.reduce((acc, curr) => acc + (parseInt(curr) || 0), 0);
                        } else {
                            sumFields += (parseInt(val) || 0);
                        }
                    });
                    totalCheckedDataCoord += sumFields;
                });
            }

            const isBalanced = (totalCheckedDataCoord === totalExpected);

            // Store the values locally right away when we run verification check
            btnInstances.forEach(b => {
                const btnId = b.id; // e.g., verify-btn-1234-0
                const indexStr = btnId.split('-').pop();
                const dTarget = window.currentDiscrepanciesList[indexStr];
                if (dTarget) {
                    dTarget.expected = totalExpected;
                    dTarget.received = totalCheckedDataCoord;
                }
                const b_div = document.getElementById(`breakdown-${safeIdPart}-${indexStr}`);
                const noteBtn = document.getElementById(`add-note-btn-${safeIdPart}-${indexStr}`);

                if (isBalanced) {
                    b.style.display = 'flex';
                    b.innerHTML = '<i class="fas fa-check-circle" style="font-size: 14px;"></i> Good';
                    b.style.color = '#10b981';
                    b.onmouseout = null;
                    b.style.transition = '';
                    
                    if (noteBtn) noteBtn.style.display = 'none';
                } else {
                    b.style.display = 'flex';
                    b.innerHTML = '<i class="fas fa-times-circle" style="font-size: 14px;"></i> Bad';
                    b.style.color = '#ef4444';
                    b.style.fontSize = ''; // revert
                    b.style.background = 'transparent';
                    b.style.padding = '';
                    b.onmouseover = null;
                    b.onmouseout = null;
                    b.style.transition = '';
                    
                    if (noteBtn) noteBtn.style.display = 'flex';
                }
            });

            if (isBalanced) {
                if(!hideAlert) {
                    window.showValidationModal("Verification Successful", `AWB ${awbNumber} has ${totalExpected} expected piece(s) and exactly ${totalCheckedDataCoord} piece(s) have been registered.`);
                }
                setTimeout(window.checkIfAllDiscrepanciesResolved, 100);
                return { ok: true, balanced: true, totalExpected, totalCheckedDataCoord };
            } else {
                if(!hideAlert) {
                    window.showValidationModal("Verification Warning", `AWB ${awbNumber} has ${totalExpected} expected piece(s) but ${totalCheckedDataCoord} piece(s) are currently registered.`);
                }
                setTimeout(window.checkIfAllDiscrepanciesResolved, 100);
                return { ok: true, balanced: false, totalExpected, totalCheckedDataCoord };
            }

        } catch (e) {
            console.error("Verification failed:", e);
            if(!hideAlert) {
                window.showValidationModal("Verification Error", "Error verifying pieces: " + e.message);
            }
            return { ok: false, error: e.message };
        }
    };

    window.runAllAwbInventoryChecks = async function() {
        const discrepancies = window.currentDiscrepanciesList || [];
        if (discrepancies.length === 0) return;
        
        const btn = document.getElementById('drawer-verify-all-btn');
        if (btn) {
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Verifying...';
            btn.disabled = true;
        }

        let uniqueAwbs = [...new Set(discrepancies.map(d => d.awb))];
        let results = [];
        
        for (const awb of uniqueAwbs) {
            const res = await window.runAwbInventoryCheck(awb, true); // true = hideAlert
            results.push({ awb, ...res });
        }
        
        let allBalanced = true;
        let warningMessages = [];
        let successMessages = [];

        results.forEach(r => {
            if (r.ok && r.balanced) {
                successMessages.push(`<div style="padding: 10px 12px; background: white; border: 1px solid #e2e8f0; border-radius: 8px; font-weight: 600; font-size: 13px; color: #0f172a; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;"><span>AWB: ${r.awb}</span> <span style="color: #16a34a; font-size: 11px; padding: 2px 8px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 12px;"><i class="fas fa-check-circle" style="margin-right: 4px;"></i>GOOD</span></div>`);
            } else if (r.ok && !r.balanced) {
                allBalanced = false;
                warningMessages.push(`<div style="padding: 10px 12px; background: white; border: 1px solid #e2e8f0; border-radius: 8px; font-weight: 600; font-size: 13px; color: #0f172a; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;"><span>AWB: ${r.awb}</span> <span style="color: #e11d48; font-size: 11px; padding: 2px 8px; background: #fff1f2; border: 1px solid #fecaca; border-radius: 12px;"><i class="fas fa-times-circle" style="margin-right: 4px;"></i>BAD</span></div>`);
            } else {
                allBalanced = false;
                warningMessages.push(`<div style="padding: 10px 12px; background: white; border: 1px solid #e2e8f0; border-radius: 8px; font-weight: 600; font-size: 13px; color: #0f172a; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;"><span>AWB: ${r.awb}</span> <span style="color: #92400e; font-size: 11px; padding: 2px 8px; background: #fffbeb; border: 1px solid #fde68a; border-radius: 12px;"><i class="fas fa-exclamation-triangle" style="margin-right: 4px;"></i>ERROR</span></div>`);
            }
        });

        if (btn) {
            btn.innerHTML = '<i class="fas fa-clipboard-check"></i> Verify All Anomalies';
            btn.disabled = false;
        }

        window.showValidationModal("Anomaly Verification Report", `<div style="text-align: left; margin-top: 16px; max-height: 50vh; overflow-y: auto; padding-right: 8px;">
            ${warningMessages.join('')}
            ${successMessages.join('')}
        </div>`, true);

        setTimeout(window.checkIfAllDiscrepanciesResolved, 150);
    };

    window.openAddAwbToUldModal = function(uldName, refCarrier, refNumber, refDate, isBreak = false) {
        window.currentActiveUldIsBreak = isBreak;
        if (refCarrier !== undefined) {
            window.currentFlightEditing = {
                carrier: refCarrier,
                number: refNumber,
                'date-arrived': refDate
            };
        }
        document.getElementById('add-awb-to-uld-title-ref').textContent = uldName;
        document.getElementById('add-awb-to-uld-awb-word').textContent = 'AWB';
        document.getElementById('add-awb-to-uld-number').value = '';
        document.getElementById('add-awb-to-uld-pcs').value = '';
        document.getElementById('add-awb-to-uld-total').value = '';
        document.getElementById('add-awb-to-uld-house').value = '';
        document.getElementById('add-awb-to-uld-wgt').value = '';
        
        window.currentAddAwbLocalItem = { agi: [], pre: [], crate: [], box: [], other: [] };
        
        ['agi', 'pre', 'crate', 'box', 'other'].forEach(id => {
            const el = document.getElementById('add-awb-to-uld-' + id);
            if(el) el.value = '';
        });
        
        const locContainer = document.getElementById('add-awb-to-uld-loc-container');
        if (locContainer) {
            locContainer.querySelectorAll('.loc-pill-small').forEach(pill => {
                pill.classList.remove('selected');
                pill.style.background = '#f1f5f9';
                pill.style.color = '#475569';
                pill.style.border = '1px solid #e2e8f0';
            });
        }
        const extraLoc = document.getElementById('add-awb-to-uld-loc-other-input');
        if (extraLoc) {
            extraLoc.style.display = 'none';
            extraLoc.value = '';
        }

        document.getElementById('add-awb-to-uld-desc').value = '';
        if(typeof window.renderLocalAwbItemsNew === 'function') {
            window.renderLocalAwbItemsNew();
        }

        const submitBtn = document.getElementById('add-awb-to-uld-submit-btn');
        if (submitBtn) {
            submitBtn.innerHTML = 'Add AWB';
            submitBtn.disabled = false;
        }

        document.getElementById('add-awb-to-uld-modal').style.display = 'flex';

        const acInput = document.getElementById('add-awb-to-uld-number');
        const acPcs = document.getElementById('add-awb-to-uld-pcs');
        const acTotal = document.getElementById('add-awb-to-uld-total');
        const acWgt = document.getElementById('add-awb-to-uld-wgt');

        // Remove old listener if exists to avoid duplicates
        const newAcInput = acInput.cloneNode(true);
        acInput.parentNode.replaceChild(newAcInput, acInput);

        let isFetchingAwbAuto = false;
        let lastFetchedAwbAuto = '';

        const triggerAutoFill = async (val) => {
            if (!val || val === lastFetchedAwbAuto || isFetchingAwbAuto) return;
            isFetchingAwbAuto = true;
            try {
                acTotal.placeholder = 'Buscando...';
                const spacelessVal = val.replace(/\s/g, ''); // For backwards compatibility with older AWBs
                
                let {data, error} = await supabaseClient
                    .from('AWB')
                    .select('total')
                    .eq('AWB number', val)
                    .maybeSingle();
                
                if (!data && !error && spacelessVal !== val) {
                    const res = await supabaseClient
                        .from('AWB')
                        .select('total')
                        .eq('AWB number', spacelessVal)
                        .maybeSingle();
                    data = res.data;
                    error = res.error;
                }
                    
                if(data && !error) {
                    if(data.total !== undefined && data.total !== null) {
                        acTotal.value = data.total;
                        // Bloquear campo
                        acTotal.readOnly = true;
                        acTotal.style.backgroundColor = '#f1f5f9';
                    }
                }
                lastFetchedAwbAuto = val;
            } catch(e) {
                console.warn("Could not fetch AWB info for autofill:", e);
            } finally {
                acTotal.placeholder = '0';
                isFetchingAwbAuto = false;
            }
        };

        newAcInput.addEventListener('input', (e) => {
            let val = e.target.value.replace(/[^\d]/g, '');
            if (val.length > 3) {
                val = val.substring(0, 3) + '-' + val.substring(3);
            }
            if (val.length > 8) {
                val = val.substring(0, 8) + ' ' + val.substring(8);
            }
            e.target.value = val;

            if (val.length < 13) {
                acTotal.readOnly = false;
                acTotal.style.backgroundColor = '';
                if (val.length < 10) lastFetchedAwbAuto = '';
            }

            if (val.length >= 13) {
                triggerAutoFill(val);
            }
        });

        newAcInput.addEventListener('blur', () => {
            const val = newAcInput.value.trim();
            if (val.length > 6) {
                triggerAutoFill(val);
            }
        });
    };

    window.currentAddAwbLocalItem = { agi: [], pre: [], crate: [], box: [], other: [] };

    window.renderLocalAwbItemsNew = function() {
        let totalChecked = 0;
        const listContainer = document.getElementById('add-awb-to-uld-local-list');
        if (!listContainer) return;

        ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
            window.currentAddAwbLocalItem[type].forEach(item => {
                totalChecked += item.qty;
            });
        });

        document.getElementById('add-awb-to-uld-total-checked').textContent = totalChecked;

        let html = '';
        const labelsMap = {
            agi: 'Agi Skid',
            pre: 'Pre Skid',
            crate: 'Crates',
            box: 'Boxes',
            other: 'Other'
        };

        ['agi', 'pre', 'crate', 'box', 'other'].forEach(type => {
            let validItems = [];
            let totalQtyForType = 0;
            window.currentAddAwbLocalItem[type].forEach((item, index) => {
                let qty = Number(item.qty || 0);
                if (qty <= 0) return; // Hide zero qty items
                validItems.push({item, index});
                totalQtyForType += qty;
            });

            if (validItems.length > 0) {
                let groupInnerHtml = '';
                let innerContent = '';

                if (type === 'agi') {
                    validItems.forEach((obj, innerPosition) => {
                        let item = obj.item;
                        let index = obj.index;
                        
                        let editQtyHtml = `<input type="number" value="${item.qty}" onchange="window.updateAgiValNew(${index}, this.value)" style="width: 60px; height: 32px; background: white; border: 1px solid #e2e8f0; border-radius: 8px; text-align: center; font-size: 13px; font-weight: 600; color: #475569; outline: none; transition: all 0.2s;" onfocus="this.style.borderColor='#cbd5e1';" onblur="this.style.borderColor='#e2e8f0';" placeholder="0">`;

                        groupInnerHtml += `
                            <div style="display: flex; flex-direction: column; background: #fff; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px 12px; margin-bottom: 6px; animation: fadeIn 0.15s ease;">
                                <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                                    <div style="display: flex; align-items: center; gap: 8px; flex: 1;">
                                        <span style="font-size: 12px; color: #64748b; font-weight: 600; min-width: 20px; text-align: left;">#${innerPosition + 1}</span>
                                        ${editQtyHtml}
                                    </div>
                                    <button onclick="window.removeLocalAwbItemNew('${type}', ${index})" style="border:none; background:none; color: #94a3b8; cursor: pointer; font-size: 18px; line-height: 1; outline: none; transition: color 0.1s; padding-right: 4px; width: 24px;" onmouseover="this.style.color='#ef4444'" onmouseout="this.style.color='#94a3b8'">&times;</button>
                                </div>
                            </div>
                        `;
                    });
                    
                    innerContent = `
                        <div style="display: flex; flex-direction: column; border-top: 1px solid #e2e8f0; padding-top: 8px; gap: 0;">
                            ${groupInnerHtml}
                        </div>
                    `;
                } else {
                    innerContent = '';
                }

                let bubbleValue = type === 'agi' ? validItems.length : totalQtyForType;

                let headerStyle = `display: flex; align-items: center; justify-content: space-between;`;
                if (innerContent !== '') {
                    headerStyle += ` margin-bottom: 8px;`;
                }

                html += `
                    <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 12px; margin-bottom: 8px; animation: fadeIn 0.2s ease;">
                        <div style="${headerStyle}">
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <div style="background: white; border: 1px solid #cbd5e1; border-radius: 12px; min-width: 32px; height: 22px; padding: 0 4px; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 11px; color: #334155;">
                                    ${bubbleValue}
                                </div>
                                <span style="font-weight: 700; font-size: 13px; color: #0f172a; text-transform: uppercase;">${labelsMap[type]}</span>
                            </div>
                            ${type !== 'agi' ? `<button onclick="window.removeLocalAwbItemNew('${type}', 0)" style="border:none; background:none; color: #94a3b8; cursor: pointer; font-size: 18px; line-height: 1; outline: none; transition: color 0.1s; padding-right: 4px;" onmouseover="this.style.color='#ef4444'" onmouseout="this.style.color='#94a3b8'">&times;</button>` : ''}
                        </div>
                        ${innerContent}
                    </div>
                `;
            }
        });

        if (!html) {
            html = '<div style="text-align: center; padding: 20px 0; color: #94a3b8; font-size: 12px; font-style: italic;">No items added yet</div>';
        }
        listContainer.innerHTML = html;
    };

    window.addLocalAwbItemNew = function(type, inputId) {
        const input = document.getElementById(inputId);
        if (!input) return;
        
        const qty = parseInt(input.value, 10);
        if(isNaN(qty) || qty <= 0) return;

        if (type === 'agi') {
            window.currentAddAwbLocalItem[type].push({ qty: qty });
        } else {
            window.currentAddAwbLocalItem[type] = [{ qty }];
        }

        input.value = '';
        window.renderLocalAwbItemsNew();
    };

    window.updateAgiValNew = function(index, val) {
        const num = parseInt(val, 10) || 0;
        if (num > 0) {
            window.currentAddAwbLocalItem['agi'][index].qty = num;
            window.renderLocalAwbItemsNew();
        }
    };

    window.removeLocalAwbItemNew = function(type, index) {
        window.currentAddAwbLocalItem[type].splice(index, 1);
        window.renderLocalAwbItemsNew();
    };

    window.submitAwbToUld = async function(overrideMismatch = false) {
        const btn = document.getElementById('add-awb-to-uld-submit-btn');
        if (!btn) return;
        
        const prevHtml = btn.innerHTML;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
        btn.disabled = true;

        try {
            const num = document.getElementById('add-awb-to-uld-number').value.trim();
            const pcs = parseInt(document.getElementById('add-awb-to-uld-pcs').value, 10) || 0;
            const total = parseInt(document.getElementById('add-awb-to-uld-total').value, 10) || 0;
            const wgt = parseFloat(document.getElementById('add-awb-to-uld-wgt').value) || 0;
            
            const agiArray = window.currentAddAwbLocalItem.agi.map(a => a.qty);
            const preArr = window.currentAddAwbLocalItem.pre.map(a => a.qty);
            const crateArr = window.currentAddAwbLocalItem.crate.map(a => a.qty);
            const boxArr = window.currentAddAwbLocalItem.box.map(a => a.qty);
            const otherArr = window.currentAddAwbLocalItem.other.map(a => a.qty);

            const agiTotal = agiArray.reduce((acc, curr) => acc + curr, 0);
            const preTotal = preArr.reduce((acc, curr) => acc + curr, 0);
            const crateTotal = crateArr.reduce((acc, curr) => acc + curr, 0);
            const boxTotal = boxArr.reduce((acc, curr) => acc + curr, 0);
            const otherTotal = otherArr.reduce((acc, curr) => acc + curr, 0);
            
            const desc = document.getElementById('add-awb-to-uld-desc').value.trim();
            const houseStr = document.getElementById('add-awb-to-uld-house').value.trim();
            
            let locVal = '';
            const container = document.getElementById('add-awb-to-uld-loc-container');
            if (container) {
                const selectedPill = container.querySelector('.loc-pill-small.selected');
                if (selectedPill) {
                    if (selectedPill.textContent.trim().toLowerCase() === 'other') {
                        locVal = document.getElementById('add-awb-to-uld-loc-other-input').value.trim();
                    } else {
                        locVal = selectedPill.textContent.trim();
                    }
                }
            }

            const targetUldName = document.getElementById('add-awb-to-uld-title-ref').textContent;
            
            if (!num) {
                window.showValidationModal("Missing Information", "Please enter a valid AWB Number.");
                btn.innerHTML = prevHtml;
                btn.disabled = false;
                return;
            }

            if(pcs <= 0) {
                window.showValidationModal("Missing Information", "Please enter valid Pieces.");
                btn.innerHTML = prevHtml;
                btn.disabled = false;
                return;
            }

            const currentFlight = window.currentFlightEditing;
            if(!currentFlight) {
                window.showValidationModal("Error", "No active flight session found.");
                btn.innerHTML = prevHtml;
                btn.disabled = false;
                return;
            }

            const totalChecked = agiTotal + preTotal + crateTotal + boxTotal + otherTotal;
            const hasMismatch = pcs > 0 && totalChecked !== pcs;

            if (!overrideMismatch && hasMismatch) {
                const overlay = document.getElementById('mismatch-overlay-modal');
                if (overlay) {
                    const titleEl = document.getElementById('mismatch-modal-title');
                    const descEl = document.getElementById('mismatch-modal-desc');
                    
                    const diff = Math.abs(totalChecked - pcs);
                    const isShort = totalChecked < pcs;
                    
                    const typeStr = isShort ? 'SHORT' : 'OVER';
                    const iconColor = isShort ? '#f97316' : '#8b5cf6';
                    
                    titleEl.innerHTML = `<i class="fas fa-exclamation-circle" style="margin-right:8px; color:${iconColor};"></i> <span style="color:${iconColor};">Pieces Discrepancy (${typeStr})</span>`;
                    descEl.innerHTML = `You have checked <b>${totalChecked}</b> pieces out of <b>${pcs}</b> expected.<br><br>There is a discrepancy of <b>${diff} pieces ${typeStr}</b>.<br><br>Do you confirm that there are ${diff} pieces ${typeStr}?`;
                    
                    const overlayRep = document.getElementById('awb-mismatch-overlay-report');
                    if (overlayRep) {
                        overlayRep.value = `AWB ${num || 'NEW'}: ${diff} piece(s) ${typeStr}`;
                    }
                    
                    window.mismatchConfirmCallback = () => {
                        window.submitAwbToUld(true);
                    };
                    
                    overlay.style.display = 'flex';
                    
                    btn.innerHTML = prevHtml;
                    btn.disabled = false;
                    return; // Halt saving process until they confirm
                }
            }

            const housesArr = houseStr ? houseStr.split(',').map(h => h.trim()).filter(h => h) : [];
            
            const newNestedEntry = {
                "refULD": targetUldName,
                "refCarrier": currentFlight.carrier || '',
                "refNumber": currentFlight.number || '',
                "refDate": currentFlight['date-arrived'] || '',
                "pieces": pcs,
                "weight": wgt,
                "remarks": desc,
                "isBreak": window.currentActiveUldIsBreak === true,
                "house_number": housesArr
            };

            const piecesForCoord = totalChecked > 0 ? totalChecked : pcs;

            let mismatchStr = "";
            if (overrideMismatch) {
                const overlayRep = document.getElementById('awb-mismatch-overlay-report');
                if (overlayRep) mismatchStr = overlayRep.value.trim();
            }

            const { data: { session } } = await supabaseClient.auth.getSession();
            let userName = session?.user?.user_metadata?.name || session?.user?.email || 'Unknown User';
            if (session?.user?.id) {
                try {
                    const { data: uData } = await supabaseClient.from('Users').select('full-name').eq('ref-ID', session.user.id).single();
                    if (uData && uData['full-name']) userName = uData['full-name'];
                } catch(e){}
            }
            const checkTime = new Date().toISOString();

            const newCoordEntry = {
                awbNumber: num,
                refCarrier: currentFlight.carrier || '',
                refNumber: currentFlight.number || '',
                refDate: currentFlight['date-arrived'] || '',
                refULD: targetUldName,
                "Agi skid": agiArray.length > 0 ? agiArray : [],
                "Pre skid": preArr.length > 0 ? preArr : [],
                "Crates": crateArr.length > 0 ? crateArr : [],
                "Box": boxArr.length > 0 ? boxArr : [],
                "Other": otherArr.length > 0 ? otherArr : [],
                "Location required": locVal,
                "Total Checked": piecesForCoord,
                "Mismatch Report": mismatchStr,
                "itemLocations": {},
                "specificLocations": [],
                "house_number": housesArr,
                "Remarks": desc,
                "checkedBy": userName,
                "checkedAt": checkTime
            };

            const spacelessNum = num.replace(/\s/g, '');
            
            let existingAwb = null;
            let awbErr = null;

            if (num) {
                const res = await supabaseClient
                    .from('AWB')
                    .select('*')
                    .or(`"AWB number".eq."${num}","AWB number".eq."${spacelessNum}"`)
                    .limit(1)
                    .maybeSingle();
                existingAwb = res.data;
                awbErr = res.error;
            }

            if (awbErr && awbErr.code !== 'PGRST116') {
                throw awbErr;
            }

            if (existingAwb) {
                let currentDataAWB = Array.isArray(existingAwb['data-AWB']) ? existingAwb['data-AWB'] : [];
                const existAWBIdx = currentDataAWB.findIndex(n => 
                    n.refULD == newNestedEntry.refULD && 
                    String(n.refCarrier || '').trim().toLowerCase() == String(newNestedEntry.refCarrier).trim().toLowerCase() && 
                    String(n.refNumber || '').trim().toLowerCase() == String(newNestedEntry.refNumber).trim().toLowerCase() && 
                    String(n.refDate || '').trim().toLowerCase() == String(newNestedEntry.refDate).trim().toLowerCase()
                );

                if (existAWBIdx >= 0) {
                    currentDataAWB[existAWBIdx] = newNestedEntry;
                } else {
                    currentDataAWB.push(newNestedEntry);
                }

                let currentDataCoord = Array.isArray(existingAwb['data-coordinator']) ? existingAwb['data-coordinator'] : [];
                const existCoordIdx = currentDataCoord.findIndex(c => 
                    c.refULD == newCoordEntry.refULD && 
                    String(c.refCarrier || '').trim().toLowerCase() == String(newCoordEntry.refCarrier).trim().toLowerCase() && 
                    String(c.refNumber || '').trim().toLowerCase() == String(newCoordEntry.refNumber).trim().toLowerCase() && 
                    String(c.refDate || '').trim().toLowerCase() == String(newCoordEntry.refDate).trim().toLowerCase()
                );
                
                if (existCoordIdx >= 0) {
                    currentDataCoord[existCoordIdx] = newCoordEntry;
                } else {
                    currentDataCoord.push(newCoordEntry);
                }

                const { error: updErr } = await supabaseClient
                    .from('AWB')
                    .update({
                        'data-AWB': currentDataAWB,
                        'data-coordinator': currentDataCoord,
                        'total': total > 0 ? total : existingAwb.total
                    })
                    .eq('id', existingAwb.id);

                if (updErr) throw updErr;

            } else {
                const insertPayload = {
                    "AWB number": num,
                    "total": total > 0 ? total : pcs,
                    "data-AWB": [newNestedEntry],
                    "data-coordinator": [newCoordEntry]
                };

                const { error: insErr } = await supabaseClient
                    .from('AWB')
                    .insert([insertPayload]);

                if (insErr) throw insErr;
            }

            btn.innerHTML = 'Add AWB';
            btn.disabled = false;

            document.getElementById('add-awb-to-uld-modal').style.display = 'none';

            if (typeof window.currentActiveUldRowRefresh === 'function') {
                window.currentActiveUldRowRefresh();
            } else if (typeof window.openInlineUldView === 'function') {
                window.openInlineUldView(targetUldName, currentFlight.carrier, currentFlight.number, currentFlight['date-arrived']);
            } else if (typeof window.loadFlights === 'function') {
                window.loadFlights(false, true);
            }
            
            // Refresh discrepancies dynamically in background
            if (window.currentSelectedFlightForReports && typeof window.refreshFlightDiscrepancies === 'function') {
                window.refreshFlightDiscrepancies(window.currentSelectedFlightForReports);
            }

        } catch (e) {
            console.error("Error adding AWB to ULD:", e);
            window.showValidationModal("Error", "Failed to add AWB: " + e.message);
            btn.innerHTML = prevHtml;
            btn.disabled = false;
        }
    };

});

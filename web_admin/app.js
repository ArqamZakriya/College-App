// Firebase Configuration
const firebaseConfig = {
    apiKey: "AIzaSyA7kjm610XSlfqhfn8-31D4UIWWSNZFOXU",
    authDomain: "college-app-e6cec.firebaseapp.com",
    projectId: "college-app-e6cec",
    storageBucket: "college-app-e6cec.appspot.com",
    messagingSenderId: "717204312468",
    appId: "1:717204312468:web:f6577f1535a9ea06aa7f81",
    measurementId: "G-728X794D0K"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();
const storage = firebase.storage();

// Constants
const COLLECTIONS = {
    COLLEGES: 'colleges',
    STUDENTS: 'users',
    FACULTY: 'faculty',
    ACTIVITY: 'activity',
    NOTICES: 'notices'
};

// State Management
const state = {
    currentUser: null,
    colleges: [],
    students: [],
    faculty: [],
    activity: [],
    loading: false
};

// DOM Elements
const elements = {
    containers: {
        login: document.getElementById('login-container'),
        app: document.getElementById('app-container'),
        loading: document.getElementById('loading-overlay')
    },
    forms: {
        login: document.getElementById('login-form'),
        addCollege: document.getElementById('add-college-form'),
        editCollege: document.getElementById('edit-college-form'),
        addStudent: document.getElementById('add-student-form'),
        addFaculty: document.getElementById('add-faculty-form'),
        editFaculty: document.getElementById('edit-faculty-form')
    },
    buttons: {
        logout: document.getElementById('logout-btn'),
        addCollege: document.getElementById('add-college-btn'),
        addStudent: document.getElementById('add-student-btn'),
        addFaculty: document.getElementById('add-faculty-btn'),
        drawerToggle: document.getElementById('drawer-toggle')
    },
    filters: {
        students: document.getElementById('college-filter-students'),
        faculty: document.getElementById('college-filter-faculty')
    },
    tables: {
        colleges: document.getElementById('colleges-data'),
        students: document.getElementById('students-data'),
        faculty: document.getElementById('faculty-data'),
        activity: document.getElementById('activity-data')
    },
    stats: {
        colleges: document.getElementById('total-colleges'),
        students: document.getElementById('total-students'),
        faculty: document.getElementById('total-faculty'),
        notices: document.getElementById('active-notices')
    },
    misc: {
        adminName: document.getElementById('admin-name'),
        lastUpdated: document.getElementById('last-updated-time'),
        loginError: document.getElementById('login-error'),
        drawer: document.getElementById('drawer'),
        drawerOverlay: document.getElementById('drawer-overlay'),
        mainContent: document.querySelector('.main-content')
    }
};

// Utility Functions
const utils = {
    showElement: (element) => element.classList.remove('hidden'),
    hideElement: (element) => element.classList.add('hidden'),
    toggleLoading: (show) => {
        state.loading = show;
        if (show) {
            elements.containers.loading.classList.add('active');
        } else {
            elements.containers.loading.classList.remove('active');
        }
    },
    formatDate: (date) => {
        if (!date) return 'Never updated';
        const options = { 
            hour: '2-digit', 
            minute: '2-digit', 
            hour12: true,
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        };
        return date.toLocaleString('en-US', options);
    },
    showModal: (modal) => {
        if (!modal) return;
        modal.style.display = 'block';
        document.body.style.overflow = 'hidden';
    },
    hideModal: (modal) => {
        if (!modal) return;
        modal.style.display = 'none';
        document.body.style.overflow = 'auto';
    },
    resetForm: (form) => form && form.reset(),
    debounce: (func, delay) => {
        let timeout;
        return function() {
            const context = this;
            const args = arguments;
            clearTimeout(timeout);
            timeout = setTimeout(() => func.apply(context, args), delay);
        };
    }
};

// Data Service Layer
const dataService = {
    getColleges: async () => {
        try {
            const snapshot = await db.collection(COLLECTIONS.COLLEGES)
                .orderBy('name')
                .get();
            
            if (snapshot.empty) return [];
    
            const colleges = await Promise.all(snapshot.docs.map(async doc => {
                const data = doc.data();
                const facultyCount = await dataService.getFacultyCount(doc.id);
                
                return {
                    id: doc.id,
                    ...data,
                    facultyCount
                };
            }));
            
            // Ensure we always return an array
            return Array.isArray(colleges) ? colleges : [];
        } catch (error) {
            console.error("Error loading colleges:", error);
            return []; // Return empty array on error
        }
    },
    
    getFacultyCount: async (collegeId) => {
        try {
            const snapshot = await db.collection(COLLECTIONS.FACULTY)
                .where('collegeId', '==', collegeId)
                .get();
            return snapshot.size;
        } catch (error) {
            console.error("Error getting faculty count:", error);
            return 0;
        }
    },
    
    addCollege: async (collegeData) => {
        try {
            const data = {
                ...collegeData,
                status: 'active',
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };
            
            return await db.collection(COLLECTIONS.COLLEGES).add(data);
        } catch (error) {
            console.error("Error adding college:", error);
            throw error;
        }
    },
    
    updateCollege: async (collegeId, collegeData) => {
        try {
            return await db.collection(COLLECTIONS.COLLEGES).doc(collegeId).update({
                ...collegeData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error("Error updating college:", error);
            throw error;
        }
    },
    
    deleteCollege: async (collegeId) => {
        try {
            const [facultySnapshot, studentsSnapshot] = await Promise.all([
                db.collection(COLLECTIONS.FACULTY).where('collegeId', '==', collegeId).get(),
                db.collection(COLLECTIONS.STUDENTS).where('collegeId', '==', collegeId).get()
            ]);
            
            if (!facultySnapshot.empty || !studentsSnapshot.empty) {
                throw new Error('Cannot delete college with associated faculty or students');
            }
            
            return await db.collection(COLLECTIONS.COLLEGES).doc(collegeId).delete();
        } catch (error) {
            console.error("Error deleting college:", error);
            throw error;
        }
    },
    
    getStudents: async (collegeFilter = '') => {
        try {
            let query = db.collection(COLLECTIONS.STUDENTS).orderBy('email');
            
            const snapshot = await query.get();
            let students = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            
            if (collegeFilter) {
                students = students.filter(student => 
                    student.college.toLowerCase().includes(collegeFilter.toLowerCase())
                );
            }
            
            return students;
        } catch (error) {
            console.error("Error loading students:", error);
            throw error;
        }
    },
    
    addStudent: async (studentData) => {
        try {
            const data = {
                ...studentData,
                isEmailVerified: false,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
            };
            
            return await db.collection(COLLECTIONS.STUDENTS).add(data);
        } catch (error) {
            console.error("Error adding student:", error);
            throw error;
        }
    },
    
    updateStudent: async (studentId, studentData) => {
        try {
            return await db.collection(COLLECTIONS.STUDENTS).doc(studentId).update({
                ...studentData,
                lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error("Error updating student:", error);
            throw error;
        }
    },
    
    deleteStudent: async (studentId) => {
        try {
            return await db.collection(COLLECTIONS.STUDENTS).doc(studentId).delete();
        } catch (error) {
            console.error("Error deleting student:", error);
            throw error;
        }
    },
    
    getFaculty: async (collegeFilter = '') => {
        try {
            let query = db.collection(COLLECTIONS.FACULTY).orderBy('name');
            
            if (collegeFilter) {
                query = query.where('collegeId', '==', collegeFilter);
            }
            
            const snapshot = await query.get();
            const faculty = await Promise.all(snapshot.docs.map(async doc => {
                const data = doc.data();
                let collegeName = "Unknown";
                
                if (data.collegeId) {
                    const collegeDoc = await db.collection(COLLECTIONS.COLLEGES).doc(data.collegeId).get();
                    if (collegeDoc.exists) {
                        collegeName = collegeDoc.data().name;
                    }
                }
                
                return {
                    id: doc.id,
                    ...data,
                    collegeName
                };
            }));
            
            return faculty;
        } catch (error) {
            console.error("Error loading faculty:", error);
            throw error;
        }
    },
    
    addFaculty: async (facultyData) => {
        try {
            const data = {
                ...facultyData,
                status: 'active',
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };
            
            return await db.collection(COLLECTIONS.FACULTY).add(data);
        } catch (error) {
            console.error("Error adding faculty:", error);
            throw error;
        }
    },
    
    updateFaculty: async (facultyId, facultyData) => {
        try {
            return await db.collection(COLLECTIONS.FACULTY).doc(facultyId).update({
                ...facultyData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error("Error updating faculty:", error);
            throw error;
        }
    },
    
    deleteFaculty: async (facultyId) => {
        try {
            return await db.collection(COLLECTIONS.FACULTY).doc(facultyId).delete();
        } catch (error) {
            console.error("Error deleting faculty:", error);
            throw error;
        }
    },
    
    recordActivity: async (action) => {
        try {
            if (!state.currentUser) return;
            
            return await db.collection(COLLECTIONS.ACTIVITY).add({
                user: state.currentUser.email,
                action: action,
                timestamp: firebase.firestore.FieldValue.serverTimestamp()
            });
        } catch (error) {
            console.error("Error recording activity:", error);
        }
    },
    
    getRecentActivity: async (limit = 10) => {
        try {
            const snapshot = await db.collection(COLLECTIONS.ACTIVITY)
                .orderBy('timestamp', 'desc')
                .limit(limit)
                .get();
            
            return snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
        } catch (error) {
            console.error("Error loading activity:", error);
            return [];
        }
    },
    
    getStatistics: async () => {
        try {
            const [colleges, students, faculty, notices] = await Promise.all([
                db.collection(COLLECTIONS.COLLEGES).get(),
                db.collection(COLLECTIONS.STUDENTS).get(),
                db.collection(COLLECTIONS.FACULTY).get(),
                db.collection(COLLECTIONS.NOTICES).where('status', '==', 'active').get()
            ]);
            
            return {
                colleges: colleges.size,
                students: students.size,
                faculty: faculty.size,
                notices: notices.size
            };
        } catch (error) {
            console.error("Error loading statistics:", error);
            return {
                colleges: 0,
                students: 0,
                faculty: 0,
                notices: 0
            };
        }
    }
};

// UI Rendering Layer
const uiRenderer = {
    renderDashboard: async () => {
        try {
            utils.toggleLoading(true);
            
            const stats = await dataService.getStatistics();
            const activity = await dataService.getRecentActivity();
            
            elements.stats.colleges.textContent = stats.colleges;
            elements.stats.students.textContent = stats.students;
            elements.stats.faculty.textContent = stats.faculty;
            elements.stats.notices.textContent = stats.notices;
            
            uiRenderer.renderActivityTable(activity);
            elements.misc.lastUpdated.textContent = utils.formatDate(new Date());
        } catch (error) {
            console.error("Error loading dashboard data:", error);
            uiRenderer.showError("Error loading dashboard data");
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    renderActivityTable: (activity) => {
        if (!activity || activity.length === 0) {
            elements.tables.activity.innerHTML = `
                <tr>
                    <td colspan="4" class="no-data">No recent activity found</td>
                </tr>
            `;
            return;
        }
        
        elements.tables.activity.innerHTML = activity.map(item => `
            <tr>
                <td>${item.user}</td>
                <td>${item.action}</td>
                <td>${utils.formatDate(item.timestamp?.toDate())}</td>
                <td><span class="status-badge status-active">Completed</span></td>
            </tr>
        `).join('');
    },
    
    renderCollegesTable: (colleges) => {
        if (!colleges || colleges.length === 0) {
            elements.tables.colleges.innerHTML = `
                <tr>
                    <td colspan="7" class="no-data">No colleges found</td>
                </tr>
            `;
            return;
        }
        
        elements.tables.colleges.innerHTML = colleges.map(college => `
            <tr>
                <td>${college.id}</td>
                <td>${college.name}</td>
                <td>${college.location}</td>
                <td>${college.established}</td>
                <td>${college.facultyCount}</td>
                <td>
                    <span class="status-badge ${college.status === 'active' ? 'status-active' : 'status-inactive'}">
                        ${college.status === 'active' ? 'Active' : 'Inactive'}
                    </span>
                </td>
                <td>
                    <div class="table-actions">
                        <button class="edit-btn" data-id="${college.id}" data-type="college">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="delete-btn" data-id="${college.id}" data-type="college">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
        
        uiRenderer.bindTableActions('college');
    },
    
    renderStudentsTable: (students) => {
        if (!students || students.length === 0) {
            elements.tables.students.innerHTML = `
                <tr>
                    <td colspan="8" class="no-data">No students found</td>
                </tr>
            `;
            return;
        }
        
        elements.tables.students.innerHTML = students.map(student => `
            <tr>
                <td>${student.id}</td>
                <td>${student.name}</td>
                <td>${student.email}</td>
                <td>${student.college}</td>
                <td>${student.branch}</td>
                <td>${utils.formatDate(student.verifiedAt?.toDate())}</td>
                <td>
                    <span class="status-badge ${student.isEmailVerified ? 'status-active' : 'status-inactive'}">
                        ${student.isEmailVerified ? 'Active' : 'Inactive'}
                    </span>
                </td>
                <td>
                    <div class="table-actions">
                        <button class="edit-btn" data-id="${student.id}" data-type="student">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="delete-btn" data-id="${student.id}" data-type="student">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
        
        uiRenderer.bindTableActions('student');
    },
    
    renderFacultyTable: (faculty) => {
        if (!faculty || faculty.length === 0) {
            elements.tables.faculty.innerHTML = `
                <tr>
                    <td colspan="8" class="no-data">No faculty found</td>
                </tr>
            `;
            return;
        }
        
        elements.tables.faculty.innerHTML = faculty.map(member => `
            <tr>
                <td>${member.id}</td>
                <td>${member.name}</td>
                <td>${member.email}</td>
                <td>${member.collegeName}</td>
                <td>${member.department}</td>
                <td>${member.position}</td>
                <td>
                    <span class="status-badge ${member.status === 'active' ? 'status-active' : 'status-inactive'}">
                        ${member.status === 'active' ? 'Active' : 'Inactive'}
                    </span>
                </td>
                <td>
                    <div class="table-actions">
                        <button class="edit-btn" data-id="${member.id}" data-type="faculty">
                            <i class="fas fa-edit"></i> Edit
                        </button>
                        <button class="delete-btn" data-id="${member.id}" data-type="faculty">
                            <i class="fas fa-trash"></i> Delete
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
        
        uiRenderer.bindTableActions('faculty');
    },
    
    bindTableActions: (type) => {
        document.querySelectorAll(`.edit-btn[data-type="${type}"]`).forEach(btn => {
            btn.addEventListener('click', () => handlers[`edit${type.charAt(0).toUpperCase() + type.slice(1)}`](btn.getAttribute('data-id')));
        });
        
        document.querySelectorAll(`.delete-btn[data-type="${type}"]`).forEach(btn => {
            btn.addEventListener('click', () => handlers[`delete${type.charAt(0).toUpperCase() + type.slice(1)}`](btn.getAttribute('data-id')));
        });
    },
    
    updateCollegeOptions: () => {
        const collegeSelects = [
            elements.filters.students,
            elements.filters.faculty,
            document.getElementById('student-college'),
            document.getElementById('faculty-college'),
            document.getElementById('edit-faculty-college')
        ].filter(el => el !== null);
    
        collegeSelects.forEach(select => {
            if (!select) return;
    
            // Save current value if one is selected
            const currentValue = select.value;
            
            // Clear existing options but keep the default option if it exists
            const defaultOption = select.querySelector('option[value=""]') || 
                                (select.options.length > 0 ? select.options[0] : null);
            
            select.innerHTML = '';
            
            if (defaultOption) {
                select.appendChild(defaultOption.cloneNode(true));
            }
    
            // Check if state.colleges exists and is an array before using it
            if (Array.isArray(state.colleges) && state.colleges.length > 0) {
                state.colleges.forEach(college => {
                    const option = document.createElement('option');
                    option.value = college.id;
                    option.textContent = college.name;
                    select.appendChild(option);
                });
    
                // Restore previous selection if it exists in the new options
                if (currentValue && Array.from(select.options).some(opt => opt.value === currentValue)) {
                    select.value = currentValue;
                }
            }
        });
    },
    
    showError: (message, element = elements.misc.loginError) => {
        if (element) {
            element.textContent = message;
            setTimeout(() => element.textContent = '', 5000);
        }
    },
    
    showSuccess: (message) => {
        // In a production app, you would implement a proper notification system
        console.log(message);
        alert(message); // Simple alert for demo purposes
    }
};

// Event Handlers
const handlers = {
    handleAuthStateChange: (user) => {
        state.currentUser = user;
        
        if (user) {
            utils.hideElement(elements.containers.login);
            utils.showElement(elements.containers.app);
            elements.misc.adminName.textContent = user.email.split('@')[0];
            
            // Load initial data
            handlers.loadInitialData();
        } else {
            utils.showElement(elements.containers.login);
            utils.hideElement(elements.containers.app);
        }
    },
    
    loadInitialData: async () => {
        try {
            utils.toggleLoading(true);
            
            await Promise.all([
                handlers.loadDashboardData(),
                handlers.loadCollegesData(),
                handlers.loadStudentsData(),
                handlers.loadFacultyData()
            ]);
        } catch (error) {
            console.error("Error loading initial data:", error);
            uiRenderer.showError("Error loading initial data");
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    handleLogin: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        
        elements.misc.loginError.textContent = '';
        
        try {
            await auth.signInWithEmailAndPassword(email, password);
            await dataService.recordActivity('User logged in');
            uiRenderer.showSuccess('Login successful');
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    handleLogout: async () => {
        utils.toggleLoading(true);
        
        try {
            await auth.signOut();
            await dataService.recordActivity('User logged out');
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    toggleDrawer: () => {
        if (elements.misc.drawer.classList.contains('open')) {
            handlers.closeDrawer();
        } else {
            handlers.openDrawer();
        }
    },
    
    openDrawer: () => {
        elements.misc.drawer.classList.add('open');
        elements.misc.drawerOverlay.classList.add('active');
        elements.misc.mainContent.classList.add('drawer-open');
    },
    
    closeDrawer: () => {
        elements.misc.drawer.classList.remove('open');
        elements.misc.drawerOverlay.classList.remove('active');
        elements.misc.mainContent.classList.remove('drawer-open');
    },
    
    handleWindowResize: utils.debounce(() => {
        if (window.innerWidth > 992 && !elements.misc.drawer.classList.contains('open')) {
            handlers.openDrawer();
        }
        
        if (window.innerWidth <= 992 && elements.misc.drawer.classList.contains('open')) {
            handlers.closeDrawer();
        }
    }, 100),
    
    navigateToPage: (page) => {
        document.querySelectorAll('.nav-item').forEach(navItem => 
            navItem.classList.remove('active'));
        document.querySelector(`.nav-item[data-page="${page}"]`).classList.add('active');
        
        document.querySelectorAll('.content-page').forEach(contentPage => 
            contentPage.classList.remove('active'));
        document.getElementById(`${page}-page`).classList.add('active');
        
        if (window.innerWidth <= 992) {
            handlers.closeDrawer();
        }
        
        elements.misc.lastUpdated.textContent = utils.formatDate(new Date());
    },
    
    loadDashboardData: async () => {
        await uiRenderer.renderDashboard();
    },
    
    loadCollegesData: async () => {
        try {
            utils.toggleLoading(true);
            // Initialize with empty array
            state.colleges = [];
            
            const colleges = await dataService.getColleges();
            // Ensure we always have an array, even if getColleges returns undefined
            state.colleges = Array.isArray(colleges) ? colleges : [];
            
            uiRenderer.renderCollegesTable(state.colleges);
            uiRenderer.updateCollegeOptions();
        } catch (error) {
            console.error("Error loading colleges:", error);
            // Reset to empty array on error
            state.colleges = [];
            uiRenderer.showError("Error loading colleges");
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    loadStudentsData: async (collegeFilter = '') => {
        try {
            const students = await dataService.getStudents(collegeFilter);
            uiRenderer.renderStudentsTable(students);
        } catch (error) {
            console.error("Error loading students:", error);
            uiRenderer.showError("Error loading students");
        }
    },
    
    loadFacultyData: async (collegeFilter = '') => {
        try {
            const faculty = await dataService.getFaculty(collegeFilter);
            uiRenderer.renderFacultyTable(faculty);
        } catch (error) {
            console.error("Error loading faculty:", error);
            uiRenderer.showError("Error loading faculty");
        }
    },
    
    addCollege: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const collegeData = {
            name: document.getElementById('college-name').value,
            location: document.getElementById('college-location').value,
            established: parseInt(document.getElementById('college-established').value),
            website: document.getElementById('college-website').value || null
        };
        
        try {
            await dataService.addCollege(collegeData);
            await dataService.recordActivity(`Added new college: ${collegeData.name}`);
            uiRenderer.showSuccess('College added successfully');
            
            utils.hideModal(document.getElementById('add-college-modal'));
            utils.resetForm(elements.forms.addCollege);
            
            await handlers.loadCollegesData();
            await handlers.loadDashboardData();
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    editCollege: async (collegeId) => {
        utils.toggleLoading(true);
        
        try {
            const doc = await db.collection(COLLECTIONS.COLLEGES).doc(collegeId).get();
            
            if (doc.exists) {
                const data = doc.data();
                
                document.getElementById('edit-college-id').value = collegeId;
                document.getElementById('edit-college-name').value = data.name;
                document.getElementById('edit-college-location').value = data.location;
                document.getElementById('edit-college-established').value = data.established;
                document.getElementById('edit-college-website').value = data.website || '';
                
                utils.showModal(document.getElementById('edit-college-modal'));
            } else {
                uiRenderer.showError('College not found');
            }
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    updateCollege: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const collegeId = document.getElementById('edit-college-id').value;
        const collegeData = {
            name: document.getElementById('edit-college-name').value,
            location: document.getElementById('edit-college-location').value,
            established: parseInt(document.getElementById('edit-college-established').value),
            website: document.getElementById('edit-college-website').value || null
        };
        
        try {
            await dataService.updateCollege(collegeId, collegeData);
            await dataService.recordActivity(`Updated college: ${collegeData.name}`);
            uiRenderer.showSuccess('College updated successfully');
            
            utils.hideModal(document.getElementById('edit-college-modal'));
            utils.resetForm(elements.forms.editCollege);
            
            await handlers.loadCollegesData();
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    deleteCollege: async (collegeId) => {
        if (!confirm('Are you sure you want to delete this college? This action cannot be undone.')) {
            return;
        }
        
        utils.toggleLoading(true);
        
        try {
            await dataService.deleteCollege(collegeId);
            await dataService.recordActivity(`Deleted college with ID: ${collegeId}`);
            uiRenderer.showSuccess('College deleted successfully');
            
            await handlers.loadCollegesData();
            await handlers.loadDashboardData();
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    addStudent: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const studentData = {
            name: document.getElementById('student-name').value,
            email: document.getElementById('student-email').value,
            college: document.getElementById('student-college').value,
            branch: document.getElementById('student-branch').value
        };
        
        try {
            await dataService.addStudent(studentData);
            await dataService.recordActivity(`Added new student: ${studentData.name}`);
            uiRenderer.showSuccess('Student added successfully');
            
            utils.hideModal(document.getElementById('add-student-modal'));
            utils.resetForm(elements.forms.addStudent);
            
            await handlers.loadStudentsData(elements.filters.students.value);
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    editStudent: async (studentId) => {
        utils.toggleLoading(true);
        
        try {
            const doc = await db.collection(COLLECTIONS.STUDENTS).doc(studentId).get();
            
            if (doc.exists) {
                const data = doc.data();
                let modal = document.getElementById('edit-student-modal');
                
                if (!modal) {
                    modal = handlers.createEditStudentModal();
                }
                
                document.getElementById('edit-student-id').value = studentId;
                document.getElementById('edit-student-name').value = data.name || '';
                document.getElementById('edit-student-email').value = data.email || '';
                document.getElementById('edit-student-college').value = data.college || '';
                document.getElementById('edit-student-branch').value = data.branch || '';
                
                utils.showModal(modal);
            } else {
                uiRenderer.showError('Student not found');
            }
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    createEditStudentModal: () => {
        const modal = document.createElement('div');
        modal.id = 'edit-student-modal';
        modal.className = 'modal';
        modal.style.display = 'none';
        
        modal.innerHTML = `
            <div class="modal-content">
                <span class="close-modal">&times;</span>
                <h2>Edit Student</h2>
                <form id="edit-student-form">
                    <input type="hidden" id="edit-student-id">
                    
                    <div class="form-group">
                        <label for="edit-student-name">Name</label>
                        <input type="text" id="edit-student-name" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="edit-student-email">Email</label>
                        <input type="email" id="edit-student-email" readonly>
                    </div>
                    
                    <div class="form-group">
                        <label for="edit-student-college">College</label>
                        <input type="text" id="edit-student-college" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="edit-student-branch">Branch</label>
                        <select id="edit-student-branch" required>
                            <option value="">Select Branch</option>
                            <option value="CSE">Computer Science</option>
                            <option value="AIML">AI & ML</option>
                            <option value="ECE">Electronics</option>
                            <option value="ME">Mechanical</option>
                            <option value="CE">Civil</option>
                        </select>
                    </div>
                    
                    <div class="form-actions">
                        <button type="button" class="cancel-btn">Cancel</button>
                        <button type="submit" class="submit-btn">Save Changes</button>
                    </div>
                </form>
            </div>
        `;

        document.body.appendChild(modal);

        const form = modal.querySelector('#edit-student-form');
        if (form) {
            form.addEventListener('submit', handlers.updateStudent);
        }

        modal.querySelector('.close-modal').addEventListener('click', () => utils.hideModal(modal));
        modal.querySelector('.cancel-btn').addEventListener('click', () => utils.hideModal(modal));

        return modal;
    },
    
    updateStudent: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const studentId = document.getElementById('edit-student-id').value;
        const studentData = {
            name: document.getElementById('edit-student-name').value,
            college: document.getElementById('edit-student-college').value,
            branch: document.getElementById('edit-student-branch').value
        };
        
        try {
            await dataService.updateStudent(studentId, studentData);
            await dataService.recordActivity(`Updated student: ${studentData.name}`);
            uiRenderer.showSuccess('Student updated successfully');
            
            utils.hideModal(document.getElementById('edit-student-modal'));
            
            await handlers.loadStudentsData(elements.filters.students.value);
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    deleteStudent: async (studentId) => {
        if (!confirm('Are you sure you want to delete this student? This action cannot be undone.')) {
            return;
        }
        
        utils.toggleLoading(true);
        
        try {
            await dataService.deleteStudent(studentId);
            await dataService.recordActivity(`Deleted student with ID: ${studentId}`);
            uiRenderer.showSuccess('Student deleted successfully');
            
            await handlers.loadStudentsData(elements.filters.students.value);
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    addFaculty: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const facultyData = {
            name: document.getElementById('faculty-name').value,
            email: document.getElementById('faculty-email').value,
            collegeId: document.getElementById('faculty-college').value,
            department: document.getElementById('faculty-department').value,
            position: document.getElementById('faculty-position').value
        };
        
        try {
            await dataService.addFaculty(facultyData);
            await dataService.recordActivity(`Added new faculty: ${facultyData.name}`);
            uiRenderer.showSuccess('Faculty added successfully');
            
            utils.hideModal(document.getElementById('add-faculty-modal'));
            utils.resetForm(elements.forms.addFaculty);
            
            await handlers.loadFacultyData(elements.filters.faculty.value);
            await handlers.loadDashboardData();
            await handlers.loadCollegesData();
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    editFaculty: async (facultyId) => {
        utils.toggleLoading(true);
        
        try {
            const doc = await db.collection(COLLECTIONS.FACULTY).doc(facultyId).get();
            
            if (doc.exists) {
                const data = doc.data();
                
                document.getElementById('edit-faculty-id').value = facultyId;
                document.getElementById('edit-faculty-name').value = data.name;
                document.getElementById('edit-faculty-email').value = data.email;
                document.getElementById('edit-faculty-college').value = data.collegeId;
                document.getElementById('edit-faculty-department').value = data.department;
                document.getElementById('edit-faculty-position').value = data.position;
                
                utils.showModal(document.getElementById('edit-faculty-modal'));
            } else {
                uiRenderer.showError('Faculty member not found');
            }
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    updateFaculty: async (e) => {
        e.preventDefault();
        utils.toggleLoading(true);
        
        const facultyId = document.getElementById('edit-faculty-id').value;
        const facultyData = {
            name: document.getElementById('edit-faculty-name').value,
            email: document.getElementById('edit-faculty-email').value,
            collegeId: document.getElementById('edit-faculty-college').value,
            department: document.getElementById('edit-faculty-department').value,
            position: document.getElementById('edit-faculty-position').value
        };
        
        try {
            await dataService.updateFaculty(facultyId, facultyData);
            await dataService.recordActivity(`Updated faculty: ${facultyData.name}`);
            uiRenderer.showSuccess('Faculty updated successfully');
            
            utils.hideModal(document.getElementById('edit-faculty-modal'));
            utils.resetForm(elements.forms.editFaculty);
            
            await handlers.loadFacultyData(elements.filters.faculty.value);
            await handlers.loadDashboardData();
            await handlers.loadCollegesData();
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    },
    
    deleteFaculty: async (facultyId) => {
        if (!confirm('Are you sure you want to delete this faculty member? This action cannot be undone.')) {
            return;
        }
        
        utils.toggleLoading(true);
        
        try {
            await dataService.deleteFaculty(facultyId);
            await dataService.recordActivity(`Deleted faculty with ID: ${facultyId}`);
            uiRenderer.showSuccess('Faculty deleted successfully');
            
            await handlers.loadFacultyData(elements.filters.faculty.value);
            await handlers.loadDashboardData();
            await handlers.loadCollegesData();
        } catch (error) {
            uiRenderer.showError(error.message);
        } finally {
            utils.toggleLoading(false);
        }
    }
};

// Initialize the application
const init = () => {
    // Set up event listeners
    elements.forms.login.addEventListener('submit', handlers.handleLogin);
    elements.buttons.logout.addEventListener('click', handlers.handleLogout);
    elements.buttons.drawerToggle.addEventListener('click', handlers.toggleDrawer);
    elements.misc.drawerOverlay.addEventListener('click', handlers.closeDrawer);
    
    // Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => 
            handlers.navigateToPage(item.getAttribute('data-page')));
    });
    
    // College filters
    elements.filters.students.addEventListener('change', () => 
        handlers.loadStudentsData(elements.filters.students.value));
    elements.filters.faculty.addEventListener('change', () => 
        handlers.loadFacultyData(elements.filters.faculty.value));
    
    // Modal buttons
    elements.buttons.addCollege.addEventListener('click', () => 
        utils.showModal(document.getElementById('add-college-modal')));
    elements.buttons.addStudent.addEventListener('click', () => 
        utils.showModal(document.getElementById('add-student-modal')));
    elements.buttons.addFaculty.addEventListener('click', () => 
        utils.showModal(document.getElementById('add-faculty-modal')));
    
    // Close modals
    document.querySelectorAll('.close-modal').forEach(btn => {
        btn.addEventListener('click', () => 
            utils.hideModal(btn.closest('.modal')));
    });
    
    document.querySelectorAll('.cancel-btn').forEach(btn => {
        btn.addEventListener('click', () => 
            utils.hideModal(btn.closest('.modal')));
    });
    
    // Close modal when clicking outside
    window.addEventListener('click', (e) => {
        if (e.target.classList.contains('modal')) {
            utils.hideModal(e.target);
        }
    });
    
    // Form submissions
    elements.forms.addCollege.addEventListener('submit', handlers.addCollege);
    elements.forms.editCollege.addEventListener('submit', handlers.updateCollege);
    elements.forms.addStudent.addEventListener('submit', handlers.addStudent);
    elements.forms.addFaculty.addEventListener('submit', handlers.addFaculty);
    elements.forms.editFaculty.addEventListener('submit', handlers.updateFaculty);
    
    // Window resize
    window.addEventListener('resize', handlers.handleWindowResize);
    
    // Check auth state
    auth.onAuthStateChanged(handlers.handleAuthStateChange);
    
    // Initialize drawer state based on screen size
    if (window.innerWidth > 992) {
        handlers.openDrawer();
    }
};

// Start the application when DOM is loaded
document.addEventListener('DOMContentLoaded', init);
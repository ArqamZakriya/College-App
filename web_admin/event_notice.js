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

// DOM Elements
const loginContainer = document.getElementById('login-container');
const appContainer = document.getElementById('app-container');
const loginForm = document.getElementById('login-form');
const loginError = document.getElementById('login-error');
const logoutBtn = document.getElementById('logout-btn');
const adminName = document.getElementById('admin-name');
const navItems = document.querySelectorAll('.nav-item');
const contentPages = document.querySelectorAll('.content-page');

// Statistics elements
const totalStudentsElement = document.getElementById('total-students');
const totalFacultyElement = document.getElementById('total-faculty');
const activeNoticesElement = document.getElementById('active-notices');
const upcomingEventsElement = document.getElementById('upcoming-events');
const activityTableBody = document.getElementById('activity-data');

// Table bodies
const studentsTableBody = document.getElementById('students-data');
const facultyTableBody = document.getElementById('faculty-data');
const noticesList = document.getElementById('notices-list');
const eventsList = document.getElementById('events-list');

// Modal elements
const addStudentModal = document.getElementById('add-student-modal');
const addStudentBtn = document.getElementById('add-student-btn');
const closeModalBtns = document.querySelectorAll('.close-modal');
const addStudentForm = document.getElementById('add-student-form');

// Add Faculty Button
const addFacultyBtn = document.getElementById('add-faculty-btn');

// Add Notice Button
const addNoticeBtn = document.getElementById('add-notice-btn');

// Add Event Button
const addEventBtn = document.getElementById('add-event-btn');

// Settings Form
const saveSettingsBtn = document.getElementById('save-settings');
const collegeNameInput = document.getElementById('college-name');
const adminEmailInput = document.getElementById('admin-email');
const notificationSettingsSelect = document.getElementById('notification-settings');

// Authentication state observer
auth.onAuthStateChanged((user) => {
    if (user) {
        // User is signed in
        loginContainer.classList.add('hidden');
        appContainer.classList.remove('hidden');
        adminName.textContent = user.email.split('@')[0];
        adminEmailInput.value = user.email;
        
        // Load dashboard data
        loadDashboardData();
        
        // Load table data
        loadStudentsData();
        loadFacultyData();
        loadNoticesData();
        loadEventsData();
        
        // Load settings
        loadSettings();
    } else {
        // User is signed out
        loginContainer.classList.remove('hidden');
        appContainer.classList.add('hidden');
    }
});

// Login form submission
loginForm.addEventListener('submit', (e) => {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    loginError.textContent = '';
    
    auth.signInWithEmailAndPassword(email, password)
        .catch((error) => {
            loginError.textContent = error.message;
        });
});

// Logout button click
logoutBtn.addEventListener('click', () => {
    auth.signOut();
});

// Navigation
navItems.forEach(item => {
    item.addEventListener('click', () => {
        // Remove active class from all nav items
        navItems.forEach(navItem => navItem.classList.remove('active'));
        
        // Add active class to clicked nav item
        item.classList.add('active');
        
        // Get page ID from data attribute
        const pageId = item.getAttribute('data-page') + '-page';
        
        // Hide all content pages
        contentPages.forEach(page => page.classList.remove('active'));
        
        // Show selected content page
        document.getElementById(pageId).classList.add('active');
    });
});

// Load Dashboard Data
function loadDashboardData() {
    // Count students
    db.collection('students').get().then(snapshot => {
        totalStudentsElement.textContent = snapshot.size;
    });
    
    // Count faculty
    db.collection('faculty').get().then(snapshot => {
        totalFacultyElement.textContent = snapshot.size;
    });
    
    // Count active notices
    const currentDate = new Date();
    db.collection('notices')
        .where('expiryDate', '>=', currentDate)
        .get()
        .then(snapshot => {
            activeNoticesElement.textContent = snapshot.size;
        });
    
    // Count upcoming events
    db.collection('events')
        .where('date', '>=', currentDate)
        .get()
        .then(snapshot => {
            upcomingEventsElement.textContent = snapshot.size;
        });
    
    // Load recent activity
    db.collection('activity')
        .orderBy('timestamp', 'desc')
        .limit(10)
        .get()
        .then(snapshot => {
            activityTableBody.innerHTML = '';
            snapshot.forEach(doc => {
                const data = doc.data();
                const row = document.createElement('tr');
                
                // Format timestamp to readable date/time
                const date = data.timestamp.toDate();
                const formattedDate = new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }).format(date);
                
                row.innerHTML = `
                    <td>${data.user}</td>
                    <td>${data.action}</td>
                    <td>${formattedDate}</td>
                `;
                
                activityTableBody.appendChild(row);
            });
        });
}

// Load Students Data
function loadStudentsData() {
    db.collection('students')
        .orderBy('name')
        .get()
        .then(snapshot => {
            studentsTableBody.innerHTML = '';
            snapshot.forEach(doc => {
                const data = doc.data();
                const row = document.createElement('tr');
                
                row.innerHTML = `
                    <td>${doc.id}</td>
                    <td>${data.name}</td>
                    <td>${data.email}</td>
                    <td>${data.department}</td>
                    <td>${getYearText(data.year)}</td>
                    <td>
                        <button class="edit-btn" data-id="${doc.id}">Edit</button>
                        <button class="delete-btn" data-id="${doc.id}">Delete</button>
                    </td>
                `;
                
                studentsTableBody.appendChild(row);
            });
            
            // Add event listeners to action buttons
            addActionButtonListeners();
        });
}

// Load Faculty Data
function loadFacultyData() {
    db.collection('faculty')
        .orderBy('name')
        .get()
        .then(snapshot => {
            facultyTableBody.innerHTML = '';
            snapshot.forEach(doc => {
                const data = doc.data();
                const row = document.createElement('tr');
                
                row.innerHTML = `
                    <td>${doc.id}</td>
                    <td>${data.name}</td>
                    <td>${data.email}</td>
                    <td>${data.department}</td>
                    <td>${data.position}</td>
                    <td>
                        <button class="edit-btn" data-id="${doc.id}">Edit</button>
                        <button class="delete-btn" data-id="${doc.id}">Delete</button>
                    </td>
                `;
                
                facultyTableBody.appendChild(row);
            });
            
            // Add event listeners to action buttons
            addActionButtonListeners();
        });
}

// Load Notices Data
function loadNoticesData() {
    db.collection('notices')
        .orderBy('createdAt', 'desc')
        .get()
        .then(snapshot => {
            noticesList.innerHTML = '';
            snapshot.forEach(doc => {
                const data = doc.data();
                const card = document.createElement('div');
                card.className = 'notice-card';
                
                // Format dates
                const createdDate = data.createdAt.toDate();
                const formattedCreatedDate = new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                }).format(createdDate);
                
                card.innerHTML = `
                    <h3 class="notice-title">${data.title}</h3>
                    <p class="notice-date">Posted on: ${formattedCreatedDate}</p>
                    <div class="notice-content">${data.content}</div>
                    <div class="card-actions">
                        <button class="edit-btn" data-id="${doc.id}">Edit</button>
                        <button class="delete-btn" data-id="${doc.id}">Delete</button>
                    </div>
                `;
                
                noticesList.appendChild(card);
            });
            
            // Add event listeners to action buttons
            addActionButtonListeners();
        });
}

// Load Events Data
function loadEventsData() {
    db.collection('events')
        .orderBy('date')
        .get()
        .then(snapshot => {
            eventsList.innerHTML = '';
            snapshot.forEach(doc => {
                const data = doc.data();
                const card = document.createElement('div');
                card.className = 'event-card';
                
                // Format date
                const eventDate = data.date.toDate();
                const formattedEventDate = new Intl.DateTimeFormat('en-US', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                }).format(eventDate);
                
                card.innerHTML = `
                    <h3 class="event-title">${data.title}</h3>
                    <p class="event-date">${formattedEventDate}</p>
                    <div class="event-content">${data.description}</div>
                    <p><strong>Location:</strong> ${data.location}</p>
                    <div class="card-actions">
                        <button class="edit-btn" data-id="${doc.id}">Edit</button>
                        <button class="delete-btn" data-id="${doc.id}">Delete</button>
                    </div>
                `;
                
                eventsList.appendChild(card);
            });
            
            // Add event listeners to action buttons
            addActionButtonListeners();
        });
}

// Load Settings
function loadSettings() {
    db.collection('settings').doc('app_settings').get()
        .then(doc => {
            if (doc.exists) {
                const data = doc.data();
                collegeNameInput.value = data.collegeName || '';
                notificationSettingsSelect.value = data.notificationSettings || 'all';
            }
        });
}

// Add action button event listeners
function addActionButtonListeners() {
    // Edit buttons
    document.querySelectorAll('.edit-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const id = this.getAttribute('data-id');
            // Implement edit functionality
            console.log('Edit item with ID:', id);
        });
    });
    
    // Delete buttons
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const id = this.getAttribute('data-id');
            if (confirm('Are you sure you want to delete this item?')) {
                // Determine which collection to delete from based on the parent element
                let collection = '';
                if (this.closest('#students-data')) {
                    collection = 'students';
                } else if (this.closest('#faculty-data')) {
                    collection = 'faculty';
                } else if (this.closest('.notice-card')) {
                    collection = 'notices';
                } else if (this.closest('.event-card')) {
                    collection = 'events';
                }
                
                if (collection) {
                    deleteItem(collection, id);
                }
            }
        });
    });
}

// Delete item function
function deleteItem(collection, id) {
    db.collection(collection).doc(id).delete()
        .then(() => {
            console.log(`Item deleted from ${collection}`);
            
            // Record activity
            recordActivity(`Deleted item from ${collection}`);
            
            // Reload data
            switch (collection) {
                case 'students':
                    loadStudentsData();
                    break;
                case 'faculty':
                    loadFacultyData();
                    break;
                case 'notices':
                    loadNoticesData();
                    break;
                case 'events':
                    loadEventsData();
                    break;
            }
            
            // Reload dashboard to update counts
            loadDashboardData();
        })
        .catch(error => {
            console.error("Error deleting item: ", error);
            alert(`Error deleting item: ${error.message}`);
        });
}

// Record activity function
function recordActivity(action) {
    const user = auth.currentUser;
    if (user) {
        db.collection('activity').add({
            user: user.email,
            action: action,
            timestamp: firebase.firestore.FieldValue.serverTimestamp()
        });
    }
}

// Helper function to convert year number to text
function getYearText(year) {
    switch (parseInt(year)) {
        case 1: return 'First Year';
        case 2: return 'Second Year';
        case 3: return 'Third Year';
        case 4: return 'Fourth Year';
        default: return year;
    }
}

// Modal functionality
addStudentBtn.addEventListener('click', () => {
    addStudentModal.style.display = 'block';
});

closeModalBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        // Find parent modal
        const modal = btn.closest('.modal');
        modal.style.display = 'none';
    });
});

// Close modal when clicking outside
window.addEventListener('click', (event) => {
    if (event.target.classList.contains('modal')) {
        event.target.style.display = 'none';
    }
});

// Add Student form submission
addStudentForm.addEventListener('submit', (e) => {
    e.preventDefault();
    
    const name = document.getElementById('student-name').value;
    const email = document.getElementById('student-email').value;
    const department = document.getElementById('student-department').value;
    const year = document.getElementById('student-year').value;
    
    // Generate a unique ID
    const studentId = generateStudentId(department, year);
    
    // Add to Firestore
    db.collection('students').doc(studentId).set({
        name: name,
        email: email,
        department: department,
        year: parseInt(year),
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
    })
    .then(() => {
        console.log("Student added successfully");
        addStudentForm.reset();
        addStudentModal.style.display = 'none';
        
        // Record activity
        recordActivity('Added new student');
        
        // Reload data
        loadStudentsData();
        loadDashboardData();
    })
    .catch((error) => {
        console.error("Error adding student: ", error);
        alert(`Error adding student: ${error.message}`);
    });
});

// Generate a student ID
function generateStudentId(department, year) {
    const departmentCode = department.substring(0, 3).toUpperCase();
    const currentYear = new Date().getFullYear().toString().substr(-2);
    const randomDigits = Math.floor(1000 + Math.random() * 9000);
    return `${departmentCode}${currentYear}${year}${randomDigits}`;
}

// Save settings
saveSettingsBtn.addEventListener('click', () => {
    const collegeName = collegeNameInput.value;
    const notificationSettings = notificationSettingsSelect.value;
    
    db.collection('settings').doc('app_settings').set({
        collegeName: collegeName,
        notificationSettings: notificationSettings,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    })
    .then(() => {
        console.log("Settings saved successfully");
        alert("Settings saved successfully");
        
        // Record activity
        recordActivity('Updated application settings');
    })
    .catch((error) => {
        console.error("Error saving settings: ", error);
        alert(`Error saving settings: ${error.message}`);
    });
});

// Initialize the application
function initApp() {
    // Check if collections exist, if not create sample data
    db.collection('students').get()
        .then(snapshot => {
            if (snapshot.empty) {
                createSampleData();
            }
        });
}

// Create sample data for demonstration
function createSampleData() {
    // Add sample students
    const sampleStudents = [
        {
            id: 'CSE22101001',
            name: 'John Smith',
            email: 'john.smith@example.com',
            department: 'Computer Science',
            year: 1
        },
        {
            id: 'EEE22202002',
            name: 'Emily Johnson',
            email: 'emily.johnson@example.com',
            department: 'Electrical Engineering',
            year: 2
        }
    ];
    
    sampleStudents.forEach(student => {
        db.collection('students').doc(student.id).set({
            name: student.name,
            email: student.email,
            department: student.department,
            year: student.year,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
    });
    
    // Add sample faculty
    const sampleFaculty = [
        {
            id: 'FAC001',
            name: 'Dr. Robert Wilson',
            email: 'robert.wilson@example.com',
            department: 'Computer Science',
            position: 'Professor'
        },
        {
            id: 'FAC002',
            name: 'Dr. Sarah Lee',
            email: 'sarah.lee@example.com',
            department: 'Mathematics',
            position: 'Associate Professor'
        }
    ];
    
    sampleFaculty.forEach(faculty => {
        db.collection('faculty').doc(faculty.id).set({
            name: faculty.name,
            email: faculty.email,
            department: faculty.department,
            position: faculty.position,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
    });
    
    // Add sample notices
    const sampleNotices = [
        {
            title: 'End Semester Examination Schedule',
            content: 'The end semester examinations will begin from May 15th. All students are requested to check the detailed schedule on the college notice board.',
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            expiryDate: new Date(new Date().setDate(new Date().getDate() + 30))
        },
        {
            title: 'Annual Cultural Festival',
            content: 'The annual cultural festival "Euphoria" will be held from April 20th to April 22nd. All students are encouraged to participate.',
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            expiryDate: new Date(new Date().setDate(new Date().getDate() + 15))
        }
    ];
    
    sampleNotices.forEach(notice => {
        db.collection('notices').add(notice);
    });
    
    // Add sample events
    const sampleEvents = [
        {
            title: 'Tech Seminar: AI in Healthcare',
            description: 'A seminar on applications of artificial intelligence in modern healthcare systems by industry experts.',
            date: new Date(new Date().setDate(new Date().getDate() + 10)),
            location: 'Main Auditorium',
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        },
        {
            title: 'Annual Sports Day',
            description: 'College annual sports day with various indoor and outdoor sports competitions.',
            date: new Date(new Date().setDate(new Date().getDate() + 20)),
            location: 'College Sports Ground',
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        }
    ];
    
    sampleEvents.forEach(event => {
        db.collection('events').add(event);
    });
    
    // Add app settings
    db.collection('settings').doc('app_settings').set({
        collegeName: 'ABC College of Engineering',
        notificationSettings: 'all',
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    console.log('Sample data created successfully');
}

// Call initApp when the page loads
document.addEventListener('DOMContentLoaded', initApp);
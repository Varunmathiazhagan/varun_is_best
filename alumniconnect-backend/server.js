const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
const cors = require('cors');
const multer = require('multer');
const { parse } = require('csv-parse');
const fs = require('fs');
const schedule = require('node-schedule');
require('dotenv').config();
const debugRoutes = require('./debug_routes');

const app = express();

// Enable CORS for all origins (development only)
app.use(cors());
app.use(express.json());

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    // Create uploads directory if it doesn't exist
    const uploadsDir = 'uploads';
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir);
    }
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + '.' + file.originalname.split('.').pop());
  }
});

// For CSV uploads (disk storage, temp folder)
const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB file size limit
  },
  fileFilter: (req, file, cb) => {
    if (file.fieldname === 'resume' && file.mimetype !== 'application/pdf') {
      return cb(new Error('Only PDF files are allowed for resumes'));
    }
    if (file.fieldname === 'photo' && !file.mimetype.startsWith('image/')) {
      return cb(new Error('Only image files are allowed for photos'));
    }
    cb(null, true);
  }
});

// MongoDB Atlas Connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB Atlas'))
  .catch((err) => console.error('MongoDB connection failed:', err));

// Schemas
const adminSchema = new mongoose.Schema({
  username: String,
  password: String,
});
const studentSchema = new mongoose.Schema({
  username: String,
  password: String,
  name: String,
  rollNo: String,
  konguEmail: String,
  linkedin: String,
  phone: String,
  personalEmail: String,
  department: String,
  joiningYear: String,
  passingYear: String,
});
const alumniSchema = new mongoose.Schema({
  username: String,
  password: String,
  name: String,
  rollNo: String,
  email: String,
  department: String,
  passedOutYear: String,
  company: String,
  linkedin: String,
  phone: String,
  otherEmail: String,
  address: String,
  resume: Buffer, // Add resume field for PDF
});
const pendingAlumniSchema = new mongoose.Schema({
  name: String,
  rollNo: String,
  email: String,
  department: String,
  passedOutYear: String,
});

// Add Job and Internship schemas
const jobSchema = new mongoose.Schema({
  title: String,
  company: String,
  location: String,
  description: String,
  requirements: String,
  salary: String,
  applicationLink: String,
  contactEmail: String,
  postedBy: {
    name: String,
    alumniId: String,
  },
  createdAt: { type: Date, default: Date.now },
  expiresAt: Date,
  isActive: { type: Boolean, default: true },
});

const internshipSchema = new mongoose.Schema({
  title: String,
  company: String,
  location: String,
  description: String,
  requirements: String,
  duration: String,
  stipend: String,
  applicationLink: String,
  contactEmail: String,
  postedBy: {
    name: String,
    alumniId: String,
  },
  createdAt: { type: Date, default: Date.now },
  expiresAt: Date,
  isActive: { type: Boolean, default: true },
});

// Add Application schemas
const jobApplicationSchema = new mongoose.Schema({
  jobId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  studentName: String,
  studentEmail: String,
  studentDepartment: String,
  studentRollNo: String,
  coverLetter: String,
  status: {
    type: String,
    enum: ['pending', 'viewed', 'accepted', 'rejected'],
    default: 'pending'
  },
  appliedAt: {
    type: Date,
    default: Date.now
  }
});

const internshipApplicationSchema = new mongoose.Schema({
  internshipId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Internship',
    required: true
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  studentName: String,
  studentEmail: String,
  studentDepartment: String,
  studentRollNo: String,
  coverLetter: String,
  status: {
    type: String,
    enum: ['pending', 'viewed', 'accepted', 'rejected'],
    default: 'pending'
  },
  appliedAt: {
    type: Date,
    default: Date.now
  }
});

const Admin = mongoose.model('Admin', adminSchema);
const Student = mongoose.model('Student', studentSchema);
const Alumni = mongoose.model('Alumni', alumniSchema);
const PendingAlumni = mongoose.model('PendingAlumni', pendingAlumniSchema);

// Add Discussion Forum Schemas after the existing schemas
const questionSchema = new mongoose.Schema({
  title: String,
  content: String,
  author: String,
  authorId: String,
  authorType: String, // 'student', 'alumni', or 'admin'
  timestamp: { type: Date, default: Date.now },
  tags: [String],
  photo: String, // URL or path to the uploaded photo
  likes: { type: Number, default: 0 },
  likedBy: [String], // Array of userIds who liked this question
  comments: [{
    content: String,
    author: String,
    authorId: String,
    authorType: String,
    timestamp: { type: Date, default: Date.now },
  }],
  answers: [{
    content: String,
    author: String,
    authorId: String, 
    authorType: String,
    timestamp: { type: Date, default: Date.now },
    likes: { type: Number, default: 0 },
    likedBy: [String], // Array of userIds who liked this answer
  }]
});

const Question = mongoose.model('Question', questionSchema);
const Job = mongoose.model('Job', jobSchema);
const Internship = mongoose.model('Internship', internshipSchema);
const JobApplication = mongoose.model('JobApplication', jobApplicationSchema);
const InternshipApplication = mongoose.model('InternshipApplication', internshipApplicationSchema);

// Add Notification Schema after the existing schemas
const notificationSchema = new mongoose.Schema({
  recipient: String, // Username of the recipient
  sender: String, // Name of the sender
  senderId: String, // Username/ID of the sender
  senderType: String, // 'student' or 'alumni'
  questionId: String, // ID of the question involved
  questionTitle: String, // Title of the question for context
  type: String, // 'like', 'comment', or 'answer'
  read: { type: Boolean, default: false },
  timestamp: { type: Date, default: Date.now }
});

const Notification = mongoose.model('Notification', notificationSchema);

// Initialize Admin User
async function initializeAdmin() {
  try {
    const adminExists = await Admin.findOne({ username: 'sujith' });
    if (!adminExists) {
      const hashedPassword = await bcrypt.hash('SujithAdmin', 10);
      await Admin.create({ username: 'sujith', password: hashedPassword });
      console.log('Admin user created: sujith/SujithAdmin');
    } else {
      console.log('Admin user already exists');
    }
  } catch (err) {
    console.error('Error initializing admin:', err);
  }
}

// Nodemailer Setup
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Generate Random Password
function generatePassword() {
  return Math.random().toString(36).slice(-8);
}

// Send Email with Fallback
async function sendEmail(options) {
  try {
    await transporter.sendMail(options);
    console.log(`Email sent to ${options.to}`);
    return { success: true };
  } catch (err) {
    console.error(`Email sending error to ${options.to}:`, err.message, err.stack);
    return { success: false, error: err.message };
  }
}

// Schedule Student-to-Alumni Transition (runs every January 1st)
schedule.scheduleJob('0 0 1 1 *', async () => {
  try {
    const currentYear = new Date().getFullYear().toString();
    console.log(`Checking students for alumni transition in ${currentYear}`);
    const students = await Student.find({ passingYear: currentYear });
    
    for (const student of students) {
      const alumni = new Alumni({
        username: student.konguEmail,
        password: student.password,
        name: student.name,
        rollNo: student.rollNo,
        email: student.konguEmail,
        department: student.department,
        passedOutYear: student.passingYear,
        linkedin: student.linkedin,
        phone: student.phone,
        otherEmail: student.personalEmail,
      });

      await alumni.save();
      await Student.deleteOne({ username: student.username });

      // Send Email
      const emailResult = await sendEmail({
        from: process.env.EMAIL_USER,
        to: student.konguEmail,
        subject: 'AlumniConnect: Moved to Alumni',
        text: `You have been moved to the Alumni database.\nUsername: ${student.konguEmail}\nPassword: Your existing password`,
      });

      if (!emailResult.success) {
        console.warn(`Student moved to alumni but email failed for ${student.konguEmail}: ${emailResult.error}`);
      }
    }
    console.log(`Moved ${students.length} students to alumni`);
  } catch (err) {
    console.error('Alumni transition error:', err.message, err.stack);
  }
});

// Login Endpoint
app.post('/api/login', async (req, res) => {
  try {
    const { username, password, role } = req.body;
    if (!username || !password || !role) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    let user;
    if (role === 'admin') {
      user = await Admin.findOne({ username });
    } else if (role === 'student') {
      if (!username.match(/^[\w]+\.\d{2}[a-zA-Z]+@kongu\.edu$/)) {
        return res.status(400).json({ message: 'Invalid Kongu email format' });
      }
      user = await Student.findOne({ username });
    } else if (role === 'alumni') {
      user = await Alumni.findOne({ username });
    } else {
      return res.status(400).json({ message: 'Invalid role' });
    }

    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    res.status(200).json({ message: 'Login successful', user });
  } catch (err) {
    console.error('Login error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Admin Add Student
app.post('/api/admin/add_student', async (req, res) => {
  try {
    const { name, rollNo, konguEmail } = req.body;
    if (!name || !rollNo || !konguEmail) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const emailRegex = /^[\w]+\.\d{2}[a-zA-Z]+@kongu\.edu$/;
    if (!emailRegex.test(konguEmail)) {
      return res.status(400).json({ message: 'Invalid Kongu email format' });
    }

    const match = konguEmail.match(/\.(\d{2})([a-zA-Z]+)@/);
    if (!match) {
      return res.status(400).json({ message: 'Unable to parse department and year from email' });
    }

    const password = generatePassword();
    const hashedPassword = await bcrypt.hash(password, 10);

    const student = new Student({
      username: konguEmail,
      password: hashedPassword,
      name,
      rollNo,
      konguEmail,
      department: match[2].toUpperCase(),
      joiningYear: `20${match[1]}`,
    });

    await student.save();

    // Send Email
    const emailResult = await sendEmail({
      from: process.env.EMAIL_USER,
      to: konguEmail,
      subject: 'AlumniConnect Student Account',
      text: `Your username: ${konguEmail}\nYour password: ${password}`,
    });

    if (!emailResult.success) {
      console.warn(`Student added but email failed for ${konguEmail}: ${emailResult.error}`);
    }

    res.status(200).json({ 
      message: 'Student added successfully', 
      emailStatus: emailResult.success ? 'Email sent' : 'Email failed'
    });
  } catch (err) {
    console.error('Add student error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Admin Add Alumni
app.post('/api/admin/add_alumni', async (req, res) => {
  try {
    const { name, rollNo, email, department, passedOutYear } = req.body;
    if (!name || !rollNo || !email || !department || !passedOutYear) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const username = email.split('@')[0];
    const password = generatePassword();
    const hashedPassword = await bcrypt.hash(password, 10);

    const alumni = new Alumni({
      username,
      password: hashedPassword,
      name,
      rollNo,
      email,
      department,
      passedOutYear,
    });

    await alumni.save();

    // Send Email
    const emailResult = await sendEmail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'AlumniConnect Alumni Account',
      text: `Your username: ${username}\nYour password: ${password}`,
    });

    if (!emailResult.success) {
      console.warn(`Alumni added but email failed for ${email}: ${emailResult.error}`);
    }

    res.status(200).json({ 
      message: 'Alumni added successfully',
      emailStatus: emailResult.success ? 'Emailsent' : 'Email failed'
    });
  } catch (err) {
    console.error('Add alumni error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Admin Bulk Add Students via CSV
app.post('/api/admin/bulk_add_students', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    const students = [];
    fs.createReadStream(req.file.path)
      .pipe(parse({ columns: true, trim: true }))
      .on('data', (row) => {
        if (row.name && row.rollNo && row.konguEmail) {
          students.push(row);
        }
      })
      .on('end', async () => {
        const results = [];
        for (const student of students) {
          try {
            const emailRegex = /^[\w]+\.\d{2}[a-zA-Z]+@kongu\.edu$/;
            if (!emailRegex.test(student.konguEmail)) {
              results.push({ email: student.konguEmail, status: 'Invalid email format' });
              continue;
            }

            const match = student.konguEmail.match(/\.(\d{2})([a-zA-Z]+)@/);
            if (!match) {
              results.push({ email: student.konguEmail, status: 'Unable to parse department and year' });
              continue;
            }

            const password = generatePassword();
            const hashedPassword = await bcrypt.hash(password, 10);

            const newStudent = new Student({
              username: student.konguEmail,
              password: hashedPassword,
              name: student.name,
              rollNo: student.rollNo,
              konguEmail: student.konguEmail,
              department: match[2].toUpperCase(),
              joiningYear: `20${match[1]}`,
            });

            await newStudent.save();

            // Send Email
            const emailResult = await sendEmail({
              from: process.env.EMAIL_USER,
              to: student.konguEmail,
              subject: 'AlumniConnect Student Account',
              text: `Your username: ${student.konguEmail}\nYour password: ${password}`,
            });

            results.push({ 
              email: student.konguEmail, 
              status: emailResult.success ? 'Added successfully' : `Added but email failed: ${emailResult.error}`
            });
          } catch (err) {
            results.push({ email: student.konguEmail, status: `Error: ${err.message}` });
          }
        }

        // Clean up uploaded file
        fs.unlinkSync(req.file.path);

        res.status(200).json({ message: 'Bulk add completed', results });
      })
      .on('error', (err) => {
        console.error('CSV parsing error:', err.message, err.stack);
        res.status(500).json({ message: `CSV parsing error: ${err.message}` });
      });
  } catch (err) {
    console.error('Bulk add students error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Admin Approve Alumni
app.post('/api/admin/approve_alumni', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const pendingAlumni = await PendingAlumni.findOne({ email });
    if (!pendingAlumni) {
      return res.status(400).json({ message: 'Pending alumni not found' });
    }

    const username = pendingAlumni.email.split('@')[0];
    const password = generatePassword();
    const hashedPassword = await bcrypt.hash(password, 10);

    const alumni = new Alumni({
      username,
      password: hashedPassword,
      name: pendingAlumni.name,
      rollNo: pendingAlumni.rollNo,
      email: pendingAlumni.email,
      department: pendingAlumni.department,
      passedOutYear: pendingAlumni.passedOutYear,
    });

    await alumni.save();
    await PendingAlumni.deleteOne({ email });

    // Send Email
    const emailResult = await sendEmail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'AlumniConnect Approval',
      text: `Congratulations! You're part of Kongu Alumni.\nUsername: ${username}\nPassword: ${password}`,
    });

    if (!emailResult.success) {
      console.warn(`Alumni approved but email failed for ${email}: ${emailResult.error}`);
    }

    res.status(200).json({ 
      message: 'Alumni approved',
      emailStatus: emailResult.success ? 'Email sent' : 'Email failed'
    });
  } catch (err) {
    console.error('Approve alumni error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Admin Reject Alumni
app.post('/api/admin/reject_alumni', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const pendingAlumni = await PendingAlumni.findOne({ email });
    if (!pendingAlumni) {
      return res.status(400).json({ message: 'Pending alumni not found' });
    }

    await PendingAlumni.deleteOne({ email });

    // Send Email
    const emailResult = await sendEmail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'AlumniConnect Signup Rejected',
      text: `Dear ${pendingAlumni.name},\nYour alumni signup request has been rejected. Please contact the admin for more details.`,
    });

    if (!emailResult.success) {
      console.warn(`Alumni rejected but email failed for ${email}: ${emailResult.error}`);
    }

    res.status(200).json({ 
      message: 'Alumni request rejected',
      emailStatus: emailResult.success ? 'Email sent' : 'Email failed'
    });
  } catch (err) {
    console.error('Reject alumni error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get Pending Alumni
app.get('/api/admin/pending_alumni', async (req, res) => {
  try {
    const pendingAlumni = await PendingAlumni.find();
    res.status(200).json(pendingAlumni);
  } catch (err) {
    console.error('Get pending alumni error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Student Update
app.post('/api/student/update', async (req, res) => {
  try {
    const { username, linkedin, phone, personalEmail, department, joiningYear, passingYear } = req.body;
    if (!username) {
      return res.status(400).json({ message: 'Username is required' });
    }

    await Student.updateOne(
      { username },
      { linkedin, phone, personalEmail, department, joiningYear, passingYear }
    );
    res.status(200).json({ message: 'Details updated' });
  } catch (err) {
    console.error('Student update error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Alumni Update
app.post('/api/admin/alumni/update', async (req, res) => {
  try {
    const { username, company, linkedin, phone, otherEmail, address } = req.body;
    if (!username) {
      return res.status(400).json({ message: 'Username is required' });
    }

    await Alumni.updateOne(
      { username },
      { company, linkedin, phone, otherEmail, address }
    );
    res.status(200).json({ message: 'Details updated' });
  } catch (err) {
    console.error('Alumni update error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Change Password
app.post('/api/change_password', async (req, res) => {
  try {
    const { username, newPassword } = req.body;
    if (!username || !newPassword) {
      return res.status(400).json({ message: 'Username and new password are required' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const updated = await Student.updateOne({ username }, { password: hashedPassword }) ||
                    await Alumni.updateOne({ username }, { password: hashedPassword });
    if (updated.matchedCount === 0) {
      return res.status(400).json({ message: 'User not found' });
    }
    res.status(200).json({ message: 'Password changed' });
  } catch (err) {
    console.error('Change password error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Alumni Signup
app.post('/api/alumni/signup', async (req, res) => {
  try {
    const { name, rollNo, email, department, passedOutYear } = req.body;
    if (!name || !rollNo || !email || !department || !passedOutYear) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const pendingAlumni = new PendingAlumni({
      name,
      rollNo,
      email,
      department,
      passedOutYear,
    });

    await pendingAlumni.save();
    res.status(200).json({ message: 'Signup request sent' });
  } catch (err) {
    console.error('Alumni signup error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Manual Trigger for Alumni Transition (for testing)
app.post('/api/check_alumni_transition', async (req, res) => {
  try {
    const currentYear = new Date().getFullYear().toString();
    const students = await Student.find({ passingYear: currentYear });
    
    for (const student of students) {
      const alumni = new Alumni({
        username: student.konguEmail,
        password: student.password,
        name: student.name,
        rollNo: student.rollNo,
        email: student.konguEmail,
        department: student.department,
        passedOutYear: student.passingYear,
        linkedin: student.linkedin,
        phone: student.phone,
        otherEmail: student.personalEmail,
      });

      await alumni.save();
      await Student.deleteOne({ username: student.username });

      // Send Email
      const emailResult = await sendEmail({
        from: process.env.EMAIL_USER,
        to: student.konguEmail,
        subject: 'AlumniConnect: Moved to Alumni',
        text: `You have been moved to the Alumni database.\nUsername: ${student.konguEmail}\nPassword: Your existing password`,
      });

      if (!emailResult.success) {
        console.warn(`Student moved to alumni but email failed for ${student.konguEmail}: ${emailResult.error}`);
      }
    }
    res.status(200).json({ message: `Moved ${students.length} students to alumni` });
  } catch (err) {
    console.error('Manual alumni transition error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

app.get('/api/alumni', async (req, res) => {
  try {
    const alumni = await Alumni.find().select(
      'name department passedOutYear company linkedin'
    );
    res.status(200).json(alumni);
  } catch (err) {
    console.error('Get alumni error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Multer for resume upload (PDF only, in-memory)
const resumeUpload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') cb(null, true);
    else cb(new Error('Only PDF files are allowed'), false);
  }
});

// Alumni Resume Upload Endpoint
app.post('/api/alumni/upload_resume', resumeUpload.single('resume'), async (req, res) => {
  try {
    const { username } = req.body;
    if (!username || !req.file) {
      return res.status(400).json({ message: 'Username and PDF file are required' });
    }
    await Alumni.updateOne(
      { username },
      { resume: req.file.buffer }
    );
    res.status(200).json({ message: 'Resume uploaded successfully' });
  } catch (err) {
    console.error('Resume upload error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Alumni Resume Download Endpoint
app.get('/api/alumni/resume/:username', async (req, res) => {
  try {
    const { username } = req.params;
    const alumni = await Alumni.findOne({ username });
    if (!alumni || !alumni.resume) {
      return res.status(404).json({ message: 'Resume not found' });
    }
    res.set('Content-Type', 'application/pdf');
    res.send(alumni.resume);
  } catch (err) {
    console.error('Resume download error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Discussion Forum API Endpoints - Add these before the server start line
// Get all questions
app.get('/api/discussions', async (req, res) => {
  try {
    // Allow filtering by tags
    const { tag, search } = req.query;
    
    let query = {};
    
    if (tag) {
      query.tags = tag;
    }
    
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { content: { $regex: search, $options: 'i' } },
        { tags: { $regex: search, $options: 'i' } }
      ];
    }
    
    const questions = await Question.find(query).sort({ timestamp: -1 });
    res.status(200).json(questions);
  } catch (err) {
    console.error('Get discussions error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Post a new question
app.post('/api/discussions/question', upload.single('photo'), async (req, res) => {
  try {
    const { title, content, author, authorId, authorType, tags } = req.body;

    if (!title || !content || !author || !authorType) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Parse tags if they're sent as JSON string
    let parsedTags;
    try {
      parsedTags = tags ? JSON.parse(tags) : ['#general'];
    } catch (e) {
      parsedTags = tags ? tags.split(',').map(tag => tag.trim()) : ['#general'];
    }

    const question = new Question({
      title,
      content,
      author,
      authorId,
      authorType,
      tags: parsedTags,
      photo: req.file ? `/uploads/${req.file.filename}` : null,
      timestamp: new Date(),
      answers: [],
    });

    await question.save();
    res.status(201).json(question);
  } catch (err) {
    console.error('Post question error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

// Post an answer to a question
app.post('/api/discussions/:questionId/answer', async (req, res) => {
  try {
    const { questionId } = req.params;
    const { content, author, authorId, authorType } = req.body;
    
    if (!content || !author || !authorType) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    const question = await Question.findById(questionId);
    if (!question) {
      return res.status(404).json({ message: 'Question not found' });
    }
    
    const answer = {
      content,
      author,
      authorId,
      authorType,
      timestamp: new Date(),
      likes: 0,
      likedBy: []
    };
    
    question.answers.push(answer);
    
    // Create notification for answer (but not if answering your own question)
    if (question.authorId !== authorId) {
      const notification = new Notification({
        recipient: question.authorId,
        sender: author,
        senderId: authorId,
        senderType: authorType,
        questionId: questionId,
        questionTitle: question.title,
        type: 'answer',
      });
      
      await notification.save();
    }
    
    await question.save();
    
    res.status(201).json(question);
  } catch (err) {
    console.error('Post answer error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Like an answer
app.post('/api/discussions/:questionId/answer/:answerId/like', async (req, res) => {
  try {
    const { questionId, answerId } = req.params;
    const { userId } = req.body;
    
    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }
    
    const question = await Question.findById(questionId);
    if (!question) {
      return res.status(404).json({ message: 'Question not found' });
    }
    
    const answerIndex = question.answers.findIndex(a => a._id.toString() === answerId);
    if (answerIndex === -1) {
      return res.status(404).json({ message: 'Answer not found' });
    }
    
    // Check if user already liked this answer
    const alreadyLiked = question.answers[answerIndex].likedBy.includes(userId);
    
    if (alreadyLiked) {
      // Remove like
      question.answers[answerIndex].likes--;
      question.answers[answerIndex].likedBy = question.answers[answerIndex].likedBy
        .filter(id => id !== userId);
    } else {
      // Add like
      question.answers[answerIndex].likes++;
      question.answers[answerIndex].likedBy.push(userId);
    }
    
    await question.save();
    
    res.status(200).json({ 
      liked: !alreadyLiked,
      likes: question.answers[answerIndex].likes 
    });
  } catch (err) {
    console.error('Like answer error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Like a question
app.post('/api/discussions/:questionId/like', async (req, res) => {
  try {
    const { questionId } = req.params;
    const { userId, senderName, senderType } = req.body;
    
    if (!userId) {
      return res.status(400).json({ message: 'User ID is required' });
    }
    
    const question = await Question.findById(questionId);
    if (!question) {
      return res.status(404).json({ message: 'Question not found' });
    }
    
    // Check if user already liked this question
    const alreadyLiked = question.likedBy && question.likedBy.includes(userId);
    
    if (alreadyLiked) {
      // Remove like
      question.likes = (question.likes || 0) - 1;
      question.likedBy = question.likedBy.filter(id => id !== userId);
    } else {
      // Add like
      question.likes = (question.likes || 0) + 1;
      if (!question.likedBy) question.likedBy = [];
      question.likedBy.push(userId);
      
      // Only create notification when adding a like (not when removing)
      // Don't notify if liking your own question
      if (question.authorId !== userId) {
        // Get sender info from request body
        
        // Create notification for the question author
        const notification = new Notification({
          recipient: question.authorId,
          sender: senderName,
          senderId: userId,
          senderType: senderType,
          questionId: questionId,
          questionTitle: question.title,
          type: 'like',
        });
        
        await notification.save();
      }
    }
    
    await question.save();
    
    res.status(200).json({ 
      liked: !alreadyLiked,
      likes: question.likes 
    });
  } catch (err) {
    console.error('Like question error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Add a comment to a question
app.post('/api/discussions/:questionId/comment', async (req, res) => {
  try {
    const { questionId } = req.params;
    const { content, author, authorId, authorType } = req.body;
    
    if (!content || !author || !authorType) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    const question = await Question.findById(questionId);
    if (!question) {
      return res.status(404).json({ message: 'Question not found' });
    }
    
    const comment = {
      content,
      author,
      authorId,
      authorType,
      timestamp: new Date()
    };
    
    if (!question.comments) question.comments = [];
    question.comments.push(comment);
    
    // Create notification for comment (but not if commenting on your own question)
    if (question.authorId !== authorId) {
      const notification = new Notification({
        recipient: question.authorId,
        sender: author,
        senderId: authorId,
        senderType: authorType,
        questionId: questionId,
        questionTitle: question.title,
        type: 'comment',
      });
      
      await notification.save();
    }
    
    await question.save();
    
    res.status(201).json(question);
  } catch (err) {
    console.error('Add comment error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Job and Internship API Endpoints
// Post a new job
app.post('/api/jobs', async (req, res) => {
  try {
    const { 
      title, company, location, description, requirements,
      salary, applicationLink, contactEmail, postedBy, expiresAt 
    } = req.body;
    
    if (!title || !company || !description || !postedBy) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    const job = new Job({
      title,
      company,
      location,
      description,
      requirements,
      salary,
      applicationLink,
      contactEmail,
      postedBy,
      expiresAt: expiresAt ? new Date(expiresAt) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Default 30 days
    });
    
    await job.save();
    res.status(201).json({ message: 'Job posted successfully', job });
  } catch (err) {
    console.error('Job posting error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get all jobs
app.get('/api/jobs', async (req, res) => {
  try {
    const { active } = req.query;
    let query = {};
    
    if (active === 'true') {
      query = { 
        isActive: true,
        expiresAt: { $gt: new Date() }
      };
    }
    
    const jobs = await Job.find(query).sort({ createdAt: -1 });
    res.status(200).json(jobs);
  } catch (err) {
    console.error('Get jobs error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get job by ID
app.get('/api/jobs/:id', async (req, res) => {
  try {
    const job = await Job.findById(req.params.id);
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    res.status(200).json(job);
  } catch (err) {
    console.error('Get job error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update job
app.put('/api/jobs/:id', async (req, res) => {
  try {
    const jobId = req.params.id;
    const { postedBy } = req.body;
    
    // Ensure only the creator can update the job
    const job = await Job.findById(jobId);
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    if (job.postedBy.alumniId !== postedBy.alumniId) {
      return res.status(403).json({ message: 'Not authorized to update this job' });
    }
    
    const updatedJob = await Job.findByIdAndUpdate(jobId, req.body, { new: true });
    res.status(200).json({ message: 'Job updated successfully', job: updatedJob });
  } catch (err) {
    console.error('Update job error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Delete job
app.delete('/api/jobs/:id', async (req, res) => {
  try {
    const jobId = req.params.id;
    const { alumniId } = req.body;
    
    // Ensure only the creator can delete the job
    const job = await Job.findById(jobId);
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    if (job.postedBy.alumniId !== alumniId) {
      return res.status(403).json({ message: 'Not authorized to delete this job' });
    }
    
    await Job.findByIdAndDelete(jobId);
    res.status(200).json({ message: 'Job deleted successfully' });
  } catch (err) {
    console.error('Delete job error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Post a new internship
app.post('/api/internships', async (req, res) => {
  try {
    const { 
      title, company, location, description, requirements,
      duration, stipend, applicationLink, contactEmail, postedBy, expiresAt 
    } = req.body;
    
    if (!title || !company || !description || !postedBy) {
      return res.status(400).json({ message: 'Missing required fields' });
    }
    
    const internship = new Internship({
      title,
      company,
      location,
      description,
      requirements,
      duration,
      stipend,
      applicationLink,
      contactEmail,
      postedBy,
      expiresAt: expiresAt ? new Date(expiresAt) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Default 30 days
    });
    
    await internship.save();
    res.status(201).json({ message: 'Internship posted successfully', internship });
  } catch (err) {
    console.error('Internship posting error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get all internships
app.get('/api/internships', async (req, res) => {
  try {
    const { active } = req.query;
    let query = {};
    
    if (active === 'true') {
      query = { 
        isActive: true,
        expiresAt: { $gt: new Date() }
      };
    }
    
    const internships = await Internship.find(query).sort({ createdAt: -1 });
    res.status(200).json(internships);
  } catch (err) {
    console.error('Get internships error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get internship by ID
app.get('/api/internships/:id', async (req, res) => {
  try {
    const internship = await Internship.findById(req.params.id);
    if (!internship) {
      return res.status(404).json({ message: 'Internship not found' });
    }
    res.status(200).json(internship);
  } catch (err) {
    console.error('Get internship error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update internship
app.put('/api/internships/:id', async (req, res) => {
  try {
    const internshipId = req.params.id;
    const { postedBy } = req.body;
    
    // Ensure only the creator can update the internship
    const internship = await Internship.findById(internshipId);
    if (!internship) {
      return res.status(404).json({ message: 'Internship not found' });
    }
    
    if (internship.postedBy.alumniId !== postedBy.alumniId) {
      return res.status(403).json({ message: 'Not authorized to update this internship' });
    }
    
    const updatedInternship = await Internship.findByIdAndUpdate(internshipId, req.body, { new: true });
    res.status(200).json({ message: 'Internship updated successfully', internship: updatedInternship });
  } catch (err) {
    console.error('Update internship error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Delete internship
app.delete('/api/internships/:id', async (req, res) => {
  try {
    const internshipId = req.params.id;
    const { alumniId } = req.body;
    
    // Ensure only the creator can delete the internship
    const internship = await Internship.findById(internshipId);
    if (!internship) {
      return res.status(404).json({ message: 'Internship not found' });
    }
    
    if (internship.postedBy.alumniId !== alumniId) {
      return res.status(403).json({ message: 'Not authorized to delete this internship' });
    }
    
    await Internship.findByIdAndDelete(internshipId);
    res.status(200).json({ message: 'Internship deleted successfully' });
  } catch (err) {
    console.error('Delete internship error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Application Endpoints

// Submit job application
app.post('/api/jobs/:id/apply', async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      studentId, 
      studentName, 
      studentEmail, 
      studentDepartment, 
      studentRollNo, 
      coverLetter 
    } = req.body;
    
    // Check if the job exists
    const job = await Job.findById(id);
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    // Check if student has already applied for this job
    const existingApplication = await JobApplication.findOne({ 
      jobId: id, 
      studentId 
    });
    
    if (existingApplication) {
      return res.status(400).json({ message: 'You have already applied for this job' });
    }
    
    // Create a new application
    const application = new JobApplication({
      jobId: id,
      studentId,
      studentName,
      studentEmail,
      studentDepartment,
      studentRollNo,
      coverLetter
    });
    
    await application.save();
    
    res.status(201).json({ 
      message: 'Application submitted successfully',
      application
    });
  } catch (err) {
    console.error('Job application error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Submit internship application
app.post('/api/internships/:id/apply', async (req, res) => {
  try {
    const { id } = req.params;
    const { 
      studentId, 
      studentName, 
      studentEmail, 
      studentDepartment, 
      studentRollNo, 
      coverLetter 
    } = req.body;
    
    // Check if the internship exists
    const internship = await Internship.findById(id);
    if (!internship) {
      return res.status(404).json({ message: 'Internship not found' });
    }
    
    // Check if student has already applied for this internship
    const existingApplication = await InternshipApplication.findOne({ 
      internshipId: id, 
      studentId 
    });
    
    if (existingApplication) {
      return res.status(400).json({ message: 'You have already applied for this internship' });
    }
    
    // Create a new application
    const application = new InternshipApplication({
      internshipId: id,
      studentId,
      studentName,
      studentEmail,
      studentDepartment,
      studentRollNo,
      coverLetter
    });
    
    await application.save();
    
    res.status(201).json({ 
      message: 'Application submitted successfully',
      application
    });
  } catch (err) {
    console.error('Internship application error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get applications for a job (alumni only)
app.get('/api/jobs/:id/applications', async (req, res) => {
  try {
    const { id } = req.params;
    const { alumniId } = req.query;
    
    // Check if the job exists and belongs to the alumni
    const job = await Job.findById(id);
    if (!job) {
      return res.status(404).json({ message: 'Job not found' });
    }
    
    if (job.postedBy.alumniId !== alumniId) {
      return res.status(403).json({ message: 'Not authorized to view these applications' });
    }
    
    const applications = await JobApplication.find({ jobId: id });
    
    res.status(200).json(applications);
  } catch (err) {
    console.error('Get job applications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get applications for an internship (alumni only)
app.get('/api/internships/:id/applications', async (req, res) => {
  try {
    const { id } = req.params;
    const { alumniId } = req.query;
    
    // Check if the internship exists and belongs to the alumni
    const internship = await Internship.findById(id);
    if (!internship) {
      return res.status(404).json({ message: 'Internship not found' });
    }
    
    if (internship.postedBy.alumniId !== alumniId) {
      return res.status(403).json({ message: 'Not authorized to view these applications' });
    }
    
    const applications = await InternshipApplication.find({ internshipId: id });
    
    res.status(200).json(applications);
  } catch (err) {
    console.error('Get internship applications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update job application status (alumni only)
app.patch('/api/jobs/applications/:applicationId', async (req, res) => {
  try {
    const { applicationId } = req.params;
    const { status, alumniId } = req.body;
    
    const application = await JobApplication.findById(applicationId);
    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }
    
    // Check if the job belongs to the alumni
    const job = await Job.findById(application.jobId);
    if (!job || job.postedBy.alumniId !== alumniId) {
      return res.status(403).json({ message: 'Not authorized to update this application' });
    }
    
    application.status = status;
    await application.save();
    
    res.status(200).json({ 
      message: 'Application status updated successfully',
      application
    });
  } catch (err) {
    console.error('Update job application error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Update internship application status (alumni only)
app.patch('/api/internships/applications/:applicationId', async (req, res) => {
  try {
    const { applicationId } = req.params;
    const { status, alumniId } = req.body;
    
    const application = await InternshipApplication.findById(applicationId);
    if (!application) {
      return res.status(404).json({ message: 'Application not found' });
    }
    
    // Check if the internship belongs to the alumni
    const internship = await Internship.findById(application.internshipId);
    if (!internship || internship.postedBy.alumniId !== alumniId) {
      return res.status(403).json({ message: 'Not authorized to update this application' });
    }
    
    application.status = status;
    await application.save();
    
    res.status(200).json({ 
      message: 'Application status updated successfully',
      application
    });
  } catch (err) {
    console.error('Update internship application error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get student's job applications
app.get('/api/students/:studentId/job-applications', async (req, res) => {
  try {
    const { studentId } = req.params;
    
    // Find all applications by this student
    const applications = await JobApplication.find({ studentId });
    
    // Get details of the jobs applied for
    const jobIds = applications.map(app => app.jobId);
    const jobs = await Job.find({ _id: { $in: jobIds } });
    
    // Combine application data with job details
    const applicationDetails = applications.map(app => {
      const job = jobs.find(j => j._id.toString() === app.jobId.toString());
      return {
        application: app,
        job: job
      };
    });
    
    res.status(200).json(applicationDetails);
  } catch (err) {
    console.error('Get student job applications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get student's internship applications
app.get('/api/students/:studentId/internship-applications', async (req, res) => {
  try {
    const { studentId } = req.params;
    
    // Find all applications by this student
    const applications = await InternshipApplication.find({ studentId });
    
    // Get details of the internships applied for
    const internshipIds = applications.map(app => app.internshipId);
    const internships = await Internship.find({ _id: { $in: internshipIds } });
    
    // Combine application data with internship details
    const applicationDetails = applications.map(app => {
      const internship = internships.find(i => i._id.toString() === app.internshipId.toString());
      return {
        application: app,
        internship: internship
      };
    });
    
    res.status(200).json(applicationDetails);
  } catch (err) {
    console.error('Get student internship applications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get all applications for jobs posted by an alumni
app.get('/api/alumni/:alumniId/job-applications', async (req, res) => {
  try {
    const { alumniId } = req.params;
    
    // Find all jobs posted by this alumni
    const jobs = await Job.find({ 'postedBy.alumniId': alumniId });
    const jobIds = jobs.map(job => job._id);
    
    // Find all applications for these jobs
    const applications = await JobApplication.find({ jobId: { $in: jobIds } });
    
    // Group applications by job
    const groupedApplications = {};
    jobs.forEach(job => {
      const jobApps = applications.filter(app => app.jobId.toString() === job._id.toString());
      groupedApplications[job._id] = {
        job,
        applications: jobApps
      };
    });
    
    res.status(200).json(groupedApplications);
  } catch (err) {
    console.error('Get alumni job applications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Get all applications for internships posted by an alumni
app.get('/api/alumni/:alumniId/internship-applications', async (req, res) => {
  try {
    const { alumniId } = req.params;
    
    // Find all internships posted by this alumni
    const internships = await Internship.find({ 'postedBy.alumniId': alumniId });
    const internshipIds = internships.map(internship => internship._id);
    
    // Find all applications for these internships
    const applications = await InternshipApplication.find({ internshipId: { $in: internshipIds } });
    
    // Group applications by internship
    const groupedApplications = {};
    internships.forEach(internship => {
      const internshipApps = applications.filter(app => app.internshipId.toString() === internship._id.toString());
      groupedApplications[internship._id] = {
        internship,
        applications: internshipApps
      };
    });
    
    res.status(200).json(groupedApplications);
  } catch (err) {
    console.error('Get alumni internship applications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Add notification endpoints
// Get notifications for a user
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const notifications = await Notification.find({ recipient: userId })
      .sort({ timestamp: -1 })
      .limit(50); // Limit to most recent 50 notifications
    
    res.status(200).json(notifications);
  } catch (err) {
    console.error('Get notifications error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Mark notification as read
app.patch('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;
    const notification = await Notification.findByIdAndUpdate(
      notificationId, 
      { read: true },
      { new: true }
    );
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    
    res.status(200).json(notification);
  } catch (err) {
    console.error('Mark notification read error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Mark all user's notifications as read
app.patch('/api/notifications/:userId/read-all', async (req, res) => {
  try {
    const { userId } = req.params;
    await Notification.updateMany(
      { recipient: userId, read: false },
      { read: true }
    );
    
    res.status(200).json({ message: 'All notifications marked as read' });
  } catch (err) {
    console.error('Mark all notifications read error:', err.message, err.stack);
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

// Start Server and Initialize Admin
initializeAdmin().then(() => {
  app.listen(3000, () => console.log('Server running on port 3000'));
});
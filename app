import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, onSnapshot, updateDoc, doc } from 'firebase/firestore';
import { getAuth, onAuthStateChanged, signInWithPopup, GoogleAuthProvider, signOut } from 'firebase/auth';

// Firebase config
const firebaseConfig = {
  apiKey: "AIzaSyD4-tuWFUGMUhau868_CunvKQm0Vz95Nis",
  authDomain: "teamsphere-app.firebaseapp.com",
  projectId: "teamsphere-app",
  storageBucket: "teamsphere-app.firebasestorage.app",
  messagingSenderId: "666168949618",
  appId: "1:666168949618:web:46c3afbfbbd0b05f40bbeb"
};
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);
const provider = new GoogleAuthProvider();

function Navbar({ user, handleLogout }) {
  return (
    <nav className="bg-gray-900 text-white p-4 flex justify-between items-center shadow-md">
      <div className="font-bold text-2xl text-purple-400">TeamSphere</div>
      <div className="space-x-6">
        <Link to="/" className="hover:text-purple-300 transition-colors">Home</Link>
        <Link to="/chat" className="hover:text-purple-300 transition-colors">Chat</Link>
        <Link to="/tasks" className="hover:text-purple-300 transition-colors">Tasks</Link>
        <Link to="/ideas" className="hover:text-purple-300 transition-colors">Ideas</Link>
        <Link to="/files" className="hover:text-purple-300 transition-colors">Files</Link>
        {user ? (
          <button onClick={handleLogout} className="hover:text-red-400 ml-4">Logout</button>
        ) : null}
      </div>
    </nav>
  );
}

function Home() {
  return <div className="p-8 text-center text-white bg-gradient-to-b from-gray-900 to-black min-h-screen">Welcome to <span className="text-purple-400 font-bold">TeamSphere</span>! Start collaborating by choosing a section.</div>;
}

function Chat({ user }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "messages"), (snapshot) => {
      setMessages(snapshot.docs.map(doc => doc.data()));
    });
    return unsubscribe;
  }, []);

  const sendMessage = async () => {
    if (input.trim() && user) {
      await addDoc(collection(db, "messages"), {
        sender: user.displayName,
        text: input
      });
      setInput("");
    }
  };

  return (
    <div className="p-8 bg-black text-white min-h-screen">
      <div className="h-80 overflow-y-scroll bg-gray-800 rounded p-4 mb-4 space-y-2">
        {messages.map((msg, idx) => (
          <div key={idx} className="bg-gray-700 p-2 rounded shadow-md animate-fadeIn">
            <strong className="text-purple-300">{msg.sender}:</strong> {msg.text}
          </div>
        ))}
      </div>
      <div className="flex space-x-2">
        <input value={input} onChange={(e) => setInput(e.target.value)} className="flex-grow p-2 rounded bg-gray-800 text-white border border-gray-600" placeholder="Type a message..." />
        <button onClick={sendMessage} className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded shadow-md transition-transform hover:scale-105">Send</button>
      </div>
    </div>
  );
}

function Tasks() {
  const [tasks, setTasks] = useState([]);

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "tasks"), (snapshot) => {
      setTasks(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    return unsubscribe;
  }, []);

  const changeStatus = async (id, newStatus) => {
    await updateDoc(doc(db, "tasks", id), { status: newStatus });
  };

  return (
    <div className="p-8 bg-black text-white grid grid-cols-1 md:grid-cols-3 gap-6 min-h-screen">
      {['To Do', 'In Progress', 'Done'].map(status => (
        <div key={status} className="bg-gray-800 p-4 rounded shadow-md">
          <h2 className="font-bold text-purple-300 mb-4 text-xl">{status}</h2>
          {tasks.filter(task => task.status === status).map(task => (
            <div key={task.id} className="bg-gray-700 p-3 mb-3 rounded">
              {task.text}
              <div className="mt-2">
                {['To Do', 'In Progress', 'Done'].filter(s => s !== status).map(s => (
                  <button key={s} onClick={() => changeStatus(task.id, s)} className="text-xs text-purple-400 underline mr-2 hover:text-purple-300">{s}</button>
                ))}
              </div>
            </div>
          ))}
        </div>
      ))}
    </div>
  );
}

function Ideas() {
  const [ideas, setIdeas] = useState([]);
  const [newIdea, setNewIdea] = useState("");

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "ideas"), (snapshot) => {
      setIdeas(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    });
    return unsubscribe;
  }, []);

  const addIdea = async () => {
    if (newIdea.trim()) {
      await addDoc(collection(db, "ideas"), { text: newIdea, likes: 0 });
      setNewIdea("");
    }
  };

  const likeIdea = async (id, currentLikes) => {
    await updateDoc(doc(db, "ideas", id), { likes: currentLikes + 1 });
  };

  return (
    <div className="p-8 bg-black text-white min-h-screen">
      <div className="mb-6">
        <input value={newIdea} onChange={(e) => setNewIdea(e.target.value)} className="bg-gray-800 text-white p-2 rounded mr-2 border border-gray-600" placeholder="Share a new idea..." />
        <button onClick={addIdea} className="bg-purple-600 hover:bg-purple-700 px-4 py-2 rounded shadow-md transition-transform hover:scale-105">Post</button>
      </div>
      <div className="space-y-4">
        {ideas.map(idea => (
          <div key={idea.id} className="bg-gray-800 p-4 rounded shadow-md">
            {idea.text}
            <div className="mt-2">
              <button onClick={() => likeIdea(idea.id, idea.likes)} className="text-purple-400 hover:text-purple-300 text-sm underline">Like ({idea.likes})</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function Files() {
  const [files, setFiles] = useState([]);
  const handleUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setFiles([...files, file.name]);
    }
  };

  return (
    <div className="p-8 bg-black text-white min-h-screen">
      <input type="file" onChange={handleUpload} className="mb-4" />
      <ul className="space-y-2">
        {files.map((file, idx) => <li key={idx} className="bg-gray-800 p-3 rounded shadow-md">{file}</li>)}
      </ul>
    </div>
  );
}

export default function App() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
    });
    return unsubscribe;
  }, []);

  const handleLogin = async () => {
    await signInWithPopup(auth, provider);
  };

  const handleLogout = async () => {
    await signOut(auth);
  };

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-black text-white">
        <button onClick={handleLogin} className="bg-purple-600 px-6 py-3 rounded text-lg font-bold shadow-lg hover:bg-purple-700">Login with Google</button>
      </div>
    );
  }

  return (
    <Router>
      <Navbar user={user} handleLogout={handleLogout} />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/chat" element={<Chat user={user} />} />
        <Route path="/tasks" element={<Tasks />} />
        <Route path="/ideas" element={<Ideas />} />
        <Route path="/files" element={<Files />} />
      </Routes>
    </Router>
  );
}

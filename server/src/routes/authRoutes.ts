import { Router } from 'express';
import { register, getUserByUid } from '../controllers/authController.js';
const route = Router();
route.post('/register', register);
route.get('/by-uid/:uid', getUserByUid);
export default route;
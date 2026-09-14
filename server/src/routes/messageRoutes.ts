import { Router } from 'express';
import {
    sendMessage,
    getMessages,
    markMessagesAsRead,
    deleteMessage,
    hideMessageForMe
} from '../controllers/messageController.js';
import {
    getConversations,
    getMessageRequests,
    createOrOpenConversation,
    acceptRequest,
    declineRequest,
    blockConversation
} from '../controllers/conversationController.js';
import { messageAuth } from '../middlewares/messageAuth.js';

const router = Router();

router.use(messageAuth);

router.get('/conversations', getConversations);
router.get('/requests', getMessageRequests);
router.post('/conversations', createOrOpenConversation);

router.get('/:conversationId', getMessages);

router.post('/send', sendMessage);
router.post('/:conversationId/send', sendMessage);

router.patch('/:conversationId/accept', acceptRequest);
router.post('/:conversationId/accept', acceptRequest);

router.patch('/:conversationId/decline', declineRequest);
router.post('/:conversationId/decline', declineRequest);

router.patch('/:conversationId/read', markMessagesAsRead);

router.patch('/:conversationId/block', blockConversation);
router.post('/:conversationId/block', blockConversation);

router.delete('/:messageId', deleteMessage);
router.patch('/:messageId/hide', hideMessageForMe);

export default router;
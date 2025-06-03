import { Test, TestingModule } from '@nestjs/testing';
import { WebsocketService } from './websocket.service';
import { Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

describe('WebsocketService', () => {
  let service: WebsocketService;

  const mockSocket = {
    id: 'test-client-id',
    emit: jest.fn(),
    rooms: new Set(['test-room']),
  } as unknown as Socket;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebsocketService,
        {
          provide: Logger,
          useValue: {
            log: jest.fn(),
            error: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<WebsocketService>(WebsocketService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('handleConnection', () => {
    it('should add client to connected clients', () => {
      service.handleConnection(mockSocket);
      expect(service.getConnectedClients().get(mockSocket.id)).toBe(mockSocket);
    });
  });

  describe('handleDisconnect', () => {
    it('should remove client from connected clients', () => {
      service.handleConnection(mockSocket);
      service.handleDisconnect(mockSocket);
      expect(service.getConnectedClients().has(mockSocket.id)).toBeFalsy();
    });
  });

  describe('broadcastToAll', () => {
    it('should broadcast to all connected clients', () => {
      const event = 'test-event';
      const payload = { message: 'test message' };

      service.handleConnection(mockSocket);
      service.broadcastToAll(event, payload);

      expect(mockSocket.emit).toHaveBeenCalledWith(event, payload);
    });
  });

  describe('broadcastToRoom', () => {
    it('should broadcast to clients in specific room', () => {
      const room = 'test-room';
      const event = 'test-event';
      const payload = { message: 'test message' };

      service.handleConnection(mockSocket);
      service.broadcastToRoom(room, event, payload);

      expect(mockSocket.emit).toHaveBeenCalledWith(event, payload);
    });
  });
});

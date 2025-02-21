import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import  { CreateNotificationDto } from '../dtos/notification.dto';

@Injectable()
export class NotificationService {
  constructor(private readonly prisma: PrismaService) {}

  async createNotification(data: CreateNotificationDto) {
    const { userId, isRead, message, type} = data
    return await this.prisma.notification.create({ data:{
       userId,
       message,
       type,
       isRead
    }
    })
  }

  async getNotifications(userId: string, isRead?: boolean){
    const user = await this.prisma.user.findUnique({where:{id: userId}})
    if(!user){
      throw new NotFoundException('User not found');
    }
    const notifications = await this.prisma.notification.findMany({where: {userId, isRead}})
    if(!notifications || notifications.length === 0){
      return {data: [], totalcount: notifications.length}
    }

    return {data: notifications, totalcount: notifications.length }
  }


  async markAsRead(id: string) {  
    const notification = await this.prisma.notification.findUnique({ where: { id } });
  
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
      const updated = await this.prisma.notification.update({
      where: { id },  
      data: { isRead: true }, 
    });
    return {isRead: updated.isRead, message: 'marked'}
  }

  async deleteNotification(id: string) {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundException('Notification not found');
    }
    await this.prisma.notification.delete({ where: { id } });
    return {data: true, message: 'Deleted'}
  }
  }
